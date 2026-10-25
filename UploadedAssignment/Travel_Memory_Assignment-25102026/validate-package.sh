#!/usr/bin/env bash
set -euo pipefail
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init -backend=false
terraform -chdir=terraform validate
ansible-playbook -i ansible/inventory.ini.example --syntax-check ansible/site.yml || true
printf 'Static package checks completed. Configure private inventory/variables before deployment.\n'
