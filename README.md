# IOTBTech Cloud & DevOps Guided Project

End-to-end pipeline built in three phases: Terraform builds the server, Ansible configures it,
Docker packages the application, and GitHub Actions ships it.

| Phase | Folder | Focus | Status |
|:--:|---|---|---|
| 1 | [Phase 1](Phase%201/README.md) | Provision AWS infrastructure with Terraform, configure it with Ansible | Complete |
| 2 | [Phase 2](Phase%202/README.md) | Containerize the application and push it to Amazon ECR | Complete |
| 3 | Phase 3 | Deploy with a GitHub Actions CI/CD pipeline | Not started |

Each phase has its own README with the steps, the evidence and the errors hit along the way.

> Never commit private keys, `terraform.tfstate`, `terraform.tfvars` or `.env` files.
> Redact public IPs, instance IDs and account IDs from screenshots.
