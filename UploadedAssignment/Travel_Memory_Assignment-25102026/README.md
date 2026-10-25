# TravelMemory MERN Deployment using Terraform and Ansible

## Assignment objective
Deploy the TravelMemory MERN application on AWS using Terraform for infrastructure provisioning and Ansible for configuration, deployment, MongoDB security, and host hardening.

## Architecture
- AWS VPC: `10.20.0.0/16`
- Public subnet: web EC2 instance, Internet Gateway, inbound SSH restricted to the administrator's `/32`, application on TCP 3000
- Private subnet: MongoDB EC2 instance with no public IP, outbound updates through a NAT Gateway
- MongoDB TCP 27017: allowed only from the web-server security group
- Terraform: creates network, routes, security groups, IAM role/profile, encrypted EC2 volumes, and outputs
- Ansible: installs Node.js, NPM, Nginx, MongoDB, deploys the application, creates a MongoDB user, configures UFW, disables root SSH, and creates a systemd service

## Repository layout
```text
terraform/       AWS infrastructure as code
ansible/         Configuration and deployment playbooks
backend/         Original TravelMemory Express backend
frontend/        Original TravelMemory React frontend
screenshots/     Submission evidence using fixed names
IMPLEMENTATION_REPORT.md
SUBMISSION_LINK.txt
```

## Prerequisites
- AWS account, AWS CLI, Terraform >= 1.6, Ansible, Git
- Existing AWS EC2 key pair in the selected region
- Local SSH private key with permission `chmod 400 KEY.pem`
- A fork/copy of the original TravelMemory source in this repository under `backend/` and `frontend/`

## 1. Configure AWS credentials
```bash
aws configure
aws sts get-caller-identity
```

## 2. Provision infrastructure
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit key_name and admin_cidr. Do not commit terraform.tfvars.
terraform fmt -recursive
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output
```

## 3. Configure Ansible
```bash
cd ../ansible
ansible-galaxy collection install -r requirements.yml
cp inventory.ini.example inventory.ini
cp group_vars/all.yml.example group_vars/all.yml
```
Update `inventory.ini` with Terraform outputs. Update `group_vars/all.yml` with your repository URL and a strong MongoDB password. These real files are ignored by Git.

## 4. Test connectivity and deploy
```bash
ansible web -m ping
ansible db -m ping
ansible-playbook --syntax-check site.yml
ansible-playbook site.yml
```

Open the application URL returned by `terraform output application_url`. Add a travel record and verify it remains available after refreshing the page.

## Validation commands
```bash
curl http://WEB_PUBLIC_IP:3000
ssh -i KEY.pem ubuntu@WEB_PUBLIC_IP 'systemctl status travelmemory --no-pager'
ssh -i KEY.pem ubuntu@WEB_PUBLIC_IP 'systemctl status nginx --no-pager'
ssh -J ubuntu@WEB_PUBLIC_IP -i KEY.pem ubuntu@DB_PRIVATE_IP 'systemctl status mongod --no-pager'
```

## Screenshot evidence
The README uses fixed paths. Place screenshots in `screenshots/` with these exact names:

1. `01-terraform-init.png`
2. `02-terraform-plan.png`
3. `03-terraform-apply.png`
4. `04-aws-vpc-subnets.png`
5. `05-ec2-instances.png`
6. `06-security-groups.png`
7. `07-ansible-playbook-success.png`
8. `08-mongodb-service.png`
9. `09-travelmemory-home.png`
10. `10-travelmemory-create-record.png`
11. `11-travelmemory-record-list.png`
12. `12-terraform-destroy.png`

### Deployment evidence
![Terraform initialized](screenshots/01-terraform-init.png)
![Terraform plan](screenshots/02-terraform-plan.png)
![Terraform apply](screenshots/03-terraform-apply.png)
![AWS VPC and subnets](screenshots/04-aws-vpc-subnets.png)
![EC2 instances](screenshots/05-ec2-instances.png)
![Security groups](screenshots/06-security-groups.png)
![Ansible playbook success](screenshots/07-ansible-playbook-success.png)
![MongoDB service](screenshots/08-mongodb-service.png)
![TravelMemory home page](screenshots/09-travelmemory-home.png)
![Create travel record](screenshots/10-travelmemory-create-record.png)
![Saved travel record](screenshots/11-travelmemory-record-list.png)

## Security controls
- No database public IP
- SSH to the public server restricted to one administrator CIDR
- Database SSH and MongoDB allowed only from the web security group
- Encrypted gp3 root volumes and IMDSv2 required
- MongoDB authentication enabled; secret files excluded from Git
- Root SSH disabled; UFW enabled; application runs as a non-login service account

## Cleanup
The NAT Gateway and EC2 instances incur charges. Capture evidence, then clean up:
```bash
cd terraform
terraform destroy
```
Capture `12-terraform-destroy.png` after completion.

## Important notes
- Never commit `.pem`, `.env`, `terraform.tfvars`, Ansible inventory, passwords, or Terraform state.
- A NAT Gateway has an hourly and data-processing cost. Destroy the lab promptly.
- Replace all placeholders before deployment.

## Source application
Original application: https://github.com/UnpredictablePrashant/TravelMemory
