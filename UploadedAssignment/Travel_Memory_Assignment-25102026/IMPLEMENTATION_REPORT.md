# Implementation Report

## Project summary
This project automates a two-tier AWS deployment of the TravelMemory MERN application. Terraform provisions the AWS network and EC2 resources. Ansible configures the operating systems, deploys the React and Express components, secures MongoDB, and enables persistent services.

## Component interaction
A user connects to TCP 3000 on the public web EC2 instance. Nginx serves the compiled React frontend and proxies API requests to the Express backend on localhost TCP 3001. Express connects over the VPC private network to MongoDB on TCP 27017. MongoDB accepts traffic only from the web security group. The private server uses the NAT Gateway for package installation but accepts no unsolicited internet traffic.

## Terraform implementation
Terraform creates one VPC, one public subnet, one private subnet, an Internet Gateway, an Elastic IP and NAT Gateway, public and private route tables, web/database security groups, an EC2 IAM role, and two encrypted Ubuntu EC2 instances. Outputs provide the web public IP, DNS name, database private IP, and application URL.

## Ansible implementation
The database play installs MongoDB 7.0, binds it to localhost and its private address, creates an authenticated application user, enables authorization, and configures UFW. The web play installs Node.js 20, Nginx, and dependencies; clones the repository; writes environment settings; builds React; starts Express through systemd; and configures Nginx.

## Security design
The database has no public IP. MongoDB and database SSH are restricted to the web-server security group. Public SSH is limited to the submitted administrator `/32`. EC2 root volumes are encrypted, IMDSv2 is mandatory, root SSH login is disabled, UFW uses deny-by-default, secrets are excluded from version control, and the backend runs as a dedicated non-login account.

## Testing performed
1. `terraform validate` succeeded.
2. `terraform plan` showed the intended AWS resources.
3. Both Ansible ping tests succeeded.
4. `ansible-playbook site.yml` completed without failed hosts.
5. Nginx, TravelMemory, and MongoDB services were active.
6. The application loaded from the Terraform output URL.
7. A travel record was created and retrieved after refresh, proving frontend, API, and database communication.

## Operational considerations
The assignment architecture uses a single Availability Zone and is suitable for learning, not production high availability. A production design should use an Application Load Balancer, Auto Scaling across at least two Availability Zones, MongoDB Atlas or a replica set, TLS through ACM, Route 53, AWS Systems Manager instead of SSH, Secrets Manager, CloudWatch alarms, backups, and CI/CD.

## Cleanup
After screenshots were collected, `terraform destroy` was used to remove chargeable resources, especially the NAT Gateway and EC2 instances.
