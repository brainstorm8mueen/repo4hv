# Implementation Report

## Project summary
This project deploys the TravelMemory MERN application to AWS using Terraform and Ansible. It meets the assignment requirements for automated networking, compute, IAM, configuration management, deployment, database security, host hardening, documentation, and working-application evidence.

## Component interaction
The browser connects to Nginx on the public EC2 instance at TCP 3000. Nginx serves the compiled React files and proxies the application's actual `/trip`, `/uploads`, `/health`, and `/hello` routes to Express on localhost TCP 3001. Express uses an authenticated `MONGO_URI` to reach MongoDB over the private VPC address on TCP 27017. MongoDB has no public IP and its security group accepts MongoDB and SSH only from the web security group.

## Terraform implementation
Terraform creates one VPC, one public subnet, one private subnet, an Internet Gateway, a NAT Gateway with Elastic IP, route tables and associations, hardened security groups, an EC2 IAM role and instance profile, two encrypted Ubuntu EC2 instances, CloudWatch alarms, and deployment outputs.

## Ansible implementation
The database play installs MongoDB 7.0, binds it to localhost and the private interface, creates an authenticated application user, enables authorization, configures UFW, and disables root login. The web play installs Node.js 20 and Nginx, clones this exact repository path, installs dependencies, creates environment files, builds React, installs a systemd unit for Express, configures Nginx for the real backend routes, enables UFW, and disables root login.

## Monitoring and validation
CloudWatch monitors EC2 status checks for both hosts and CPU utilization on the web host. Operational validation includes Ansible ping, playbook syntax checking, service status checks, the `/health` endpoint, application loading, record creation, and record persistence after refresh.

## Cost-conscious design
The lab uses two `t3.micro` instances and one Availability Zone. The NAT Gateway is included because the rubric explicitly requires it and is the main avoidable lab cost, so the environment should be destroyed immediately after collecting evidence. This learning architecture is not production highly available.

## Production improvements
A production version should use an Application Load Balancer and Auto Scaling across at least two Availability Zones, TLS with ACM, Route 53, AWS Systems Manager instead of SSH, Secrets Manager, centralized logs, backups, and MongoDB Atlas or a replica set.
