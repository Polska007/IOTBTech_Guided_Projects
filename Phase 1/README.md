# Phase 1: Provision and Configure AWS Servers with Terraform and Ansible

IOTBTech Cloud & DevOps guided project. Terraform builds the servers, then Ansible configures them.

```
Terraform creates the servers  →  Ansible configures the servers
```

**Result:** Terraform created a VPC, subnet, internet gateway, route table, two security groups and two Ubuntu
24.04 EC2 instances in `eu-west-1`. Ansible, run from one of the instances, updated the other, installed and
started Docker, and verified a test web server. The final playbook run ended with
`ok=10 changed=4 unreachable=0 failed=0`. Thirteen errors came up on the way; all are listed in
[Errors encountered](#errors-encountered).

## Architecture

```
Laptop (VS Code + Terraform)
   │ terraform apply
   ▼
AWS eu-west-1 ── VPC 10.0.0.0/16 ── public subnet 10.0.1.0/24
   ├── Control node  10.0.1.10   Ansible installed; SSH allowed from my IP only
   └── Managed node  10.0.1.11   Docker installed by Ansible; port 80 open
           ▲
           └── SSH from the control node only
```

- The **control node** runs Ansible. It is the only server you SSH into from the laptop.
- The **managed node** is configured by Ansible. It accepts SSH only from the control node and HTTP from anyone.
- Ansible is installed on the control node at first boot through Terraform's `user_data`.
- The control node reaches the managed node using SSH agent forwarding, so the private key never leaves the laptop.

## Repository layout

```
Phase 1/
├── README.md
├── .gitignore               keeps keys, state and secrets out of Git
├── terraform/
│   ├── main.tf              all AWS resources
│   ├── variables.tf         input variables
│   ├── outputs.tf           IPs and the SSH config snippet
│   └── terraform.tfvars.example
├── ansible/
│   ├── ansible.cfg
│   ├── inventory.ini        the managed node's private IP
│   ├── docker.yml           the playbook
│   └── run.sh               checks, then runs the playbook
└── screenshots/
```

## What Terraform creates

| Resource | Purpose |
|---|---|
| `aws_vpc.main` | Network, `10.0.0.0/16` |
| `aws_subnet.public` | `10.0.1.0/24`, public IPs on launch |
| `aws_internet_gateway.igw` and `aws_route_table.public` (+ association) | Route `0.0.0.0/0` to the internet |
| `aws_security_group.control` | Inbound SSH (22) from `my_ip_cidr` only |
| `aws_security_group.managed` | Inbound SSH (22) from the control security group; HTTP (80) from anywhere |
| `aws_key_pair.main` | Uploads my SSH public key |
| `aws_instance.control` | Ansible control node, `10.0.1.10` |
| `aws_instance.managed` | Managed node, `10.0.1.11` |

Inputs are set in `terraform/terraform.tfvars` (copy from the `.example` file):

| Variable | Example |
|---|---|
| `region` | `eu-west-1` |
| `vpc_cidr` / `subnet_cidr` | `10.0.0.0/16` / `10.0.1.0/24` (subnet must sit inside the VPC range) |
| `instance_type` | `c7i-flex.large` (as deployed) |
| `my_ip_cidr` | `<your-public-ip>/32` |
| `public_key_path` | `C:/Users/<you>/.ssh/id_ed25519.pub` |

Outputs: `control_public_ip`, `managed_public_ips`, `managed_private_ips`, `ssh_config_snippet`.

## What Ansible does

`ansible/docker.yml` runs against the managed node with sudo:

1. Updates the apt cache and upgrades packages
2. Installs `docker.io` and `python3-docker`
3. Starts and enables the Docker service
4. Adds the `ubuntu` user to the `docker` group
5. Checks and prints the Docker version
6. Runs the `hello-world` container
7. Runs an nginx container on port 80
8. Verifies the server answers HTTP 200

`ansible/run.sh` wraps this: it confirms Ansible is installed, confirms an SSH key was forwarded, pings the
managed node, checks the playbook syntax, then runs it.

## Prerequisites

AWS account and IAM user (not root), AWS CLI (`aws configure`), Terraform 1.5+, Git, and VS Code with the
**Remote - SSH** extension.

## Deployment steps

**1. Create an SSH key and load it into the agent**
```
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
```
On Windows, start the agent once from an Administrator PowerShell
(`Start-Service ssh-agent`), then `ssh-add $HOME\.ssh\id_ed25519` and confirm with `ssh-add -l`.
Repeat `ssh-add` whenever the agent has been restarted.

**2. Configure Terraform**
```
cd "Phase 1/terraform"
cp terraform.tfvars.example terraform.tfvars    # then edit the values
```

**3. Build the infrastructure**
```
terraform init
terraform plan
terraform apply
```
Wait about a minute for Ansible to finish installing on the control node.

**4. Connect to the control node** (use `control_public_ip`, not the managed node's IP)

Add the `ssh_config_snippet` output to `~/.ssh/config` on the laptop, then:
```
ssh ansible-control        # or: ssh -A ubuntu@<control_public_ip>
```
Or use VS Code: `F1` → **Remote-SSH: Connect to Host**. Then check, on the control node:
```
ssh-add -l                 # must list your key
ssh ubuntu@10.0.1.11       # must log in; type exit to return
```

**5. Get the project onto the control node and run Ansible**
```
git clone https://github.com/<user>/<repo>.git
cd <repo>/"Phase 1"/ansible
bash run.sh
```

**6. Verify**: the recap should show `failed=0`, and `http://<managed_public_ip>` should show the nginx page.

**7. Clean up when finished**
```
cd "Phase 1/terraform" && terraform destroy
```

## Evidence

Output from the successful run (Ansible core 2.16.3):
```
node1 | SUCCESS => { "changed": false, "ping": "pong" }
Docker version 29.1.3, build 29.1.3-0ubuntu3~24.04.2

PLAY RECAP
node1 : ok=10   changed=4   unreachable=0   failed=0   skipped=0   rescued=0   ignored=0
```

Screenshots in `screenshots/` (public IPs, instance IDs and account IDs redacted):
- [ ] EC2 console with both instances running
- [ ] `terraform apply` completed
- [ ] Ansible `PLAY RECAP` with `failed=0`
- [ ] nginx page in the browser

## Security notes and open items

- The control node accepts SSH only from `my_ip_cidr`; the managed node only from the control node.
- Never commit private keys, `terraform.tfstate*`, `terraform.tfvars` or `.env` files (covered by `.gitignore`).
  State files contain account IDs and IPs.
- **Open:** during troubleshooting the control node's SSH rule was temporarily set to `0.0.0.0/0`.
  - [ ] Restored to my real IP with `/32` and applied
- No IAM role is attached to the servers yet. Phase 3 will need a way for the managed node to pull from ECR.
- Terraform state is a local file, and public IPs change if a server is stopped and started.

## Errors encountered

In the order they happened.

| # | Stage | What happened | Cause | Fix |
|---|---|---|---|---|
| 1 | Terraform files | Files from two templates were mixed (extra `providers.tf`, duplicate `variables` file, an Amazon Linux `main.tf` with invalid syntax) | Wrong files copied in | Kept one consistent set of files |
| 2 | `plan` | Prompted for every variable; VPC and subnet CIDRs swapped, `my_ip_cidr` set to `0.0.0.0/32` | Values typed by hand | Put correct values in `terraform.tfvars` |
| 3 | `plan` | `no file exists at "/c/Users/.../id_ed25519.pub"` | Git Bash path used in PowerShell | Use `C:/Users/<you>/.ssh/id_ed25519.pub` |
| 4 | `apply` | `InvalidSubnet.Range: The CIDR '10.0.0.0/16' is invalid`; VPC, gateway, route table and security groups were already created | Subnet range equal to the VPC range | Set subnet to `10.0.1.0/24` and re-applied; Terraform resumed |
| 5 | `plan` | `"10.0.0.10/16" is not a valid IPv4 CIDR block` | Mistyped at a prompt | Define all values in `terraform.tfvars` |
| 6 | `plan` | `Terraform has no command named "pln"` | Typo | `terraform plan` |
| 7 | SSH | `Connection timed out` | Connected to the managed node's IP, which only accepts SSH from the control node | Use `control_public_ip` |
| 8 | SSH | `Could not resolve hostname ansible-control` | Laptop-only SSH alias typed on the server | Use real IPs on the control node |
| 9 | SSH | `ssh-add`: `Error connecting to agent` | Windows ssh-agent service stopped | `Start-Service ssh-agent` as administrator |
| 10 | SSH | Control node to managed node: `Permission denied (publickey)` | No agent forwarding and key not loaded | `ssh-add`, reconnect with `ssh -A` |
| 11 | Git | Nothing to clone | Repository empty; placeholders unfilled | Pushed the project from the laptop, then cloned |
| 12 | Ansible | `run.sh: No such file or directory` | Run from the wrong folder | `cd` into `ansible/` first |
| 13 | Ansible | `no SSH agent keys found` at `run.sh` step 2 | New session without a forwarded key | Reconnected with `ssh -A` after loading the key |

A message `Some actions do not make sense in Ad-Hoc` also appeared once. The run did not depend on it, and its
cause was not identified.

**Pattern:** most failures came from hand-typed inputs and the SSH agent chain (laptop → control node → managed
node). The fixes were to define inputs once in `terraform.tfvars` and to have `run.sh` check for a forwarded key first.

## Cost

Both servers bill by the hour while running. Run `terraform destroy` when finished, and confirm in the EC2 console
that no instances remain.

## Next

Phase 2: containerize the application and push the image to Amazon ECR. Phase 3: deploy it with GitHub Actions.
