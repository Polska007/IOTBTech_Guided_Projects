#!/usr/bin/env bash
# Run on the Ansible control node. Checks prerequisites, tests the connection,
# validates the playbook, then installs Docker on the managed node(s).
set -euo pipefail
cd "$(dirname "$0")"

echo "==> [1/5] Checking that Ansible is installed"
if ! command -v ansible >/dev/null 2>&1; then
  echo "Ansible not found, installing..."
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ansible
fi
ansible --version | head -n 1

echo "==> [2/5] Checking that your SSH key was forwarded from the laptop"
if ! ssh-add -l >/dev/null 2>&1; then
  echo "ERROR: no SSH agent keys found. On your laptop run 'ssh-add <your key>' and reconnect with ForwardAgent yes." >&2
  exit 1
fi

echo "==> [3/5] Pinging the managed node(s)"
ansible managed -m ping

echo "==> [4/5] Validating playbook syntax"
ansible-playbook docker.yml --syntax-check

echo "==> [5/5] Running the playbook (installs and tests Docker)"
ansible-playbook docker.yml

echo "Done. Visit http://<managed_public_ip> in a browser to see nginx."
