# Screenshot Checklist - CI/CD Assignment

Use this file as your evidence tracker. Rename screenshots with the same numbering where possible.

## Local setup screenshots

- [ ] S01 - Git version installed
- [ ] S02 - Python and pip version installed
- [ ] S03 - VS Code installed
- [ ] S04 - Docker Desktop `hello-world` success
- [ ] S05 - AWS CLI version installed

## GitHub screenshots

- [ ] S06 - Forked repository under your GitHub account
- [ ] S07 - Local clone verification with `git remote -v` and `git status`
- [ ] S13 - Final local repository folder structure
- [ ] S14 - Assignment files visible in GitHub
- [ ] S21 - GitHub secrets names only, with no values visible
- [ ] S22 - Workflow running
- [ ] S23 - Full workflow successful and green
- [ ] S28 - Failed workflow at Test stage

## Flask and test screenshots

- [ ] S08 - Flask app running locally
- [ ] S09 - `/health` endpoint working locally
- [ ] S10 - PyTest passing locally

## Docker screenshots

- [ ] S11 - Docker image build successful locally
- [ ] S12 - Docker container running locally and `/health` working

## AWS screenshots

- [ ] S15 - ECR repository created
- [ ] S16 - IAM policy/user for GitHub Actions created, no secret values visible
- [ ] S17 - EC2 IAM role created
- [ ] S18 - EC2 running with public IP
- [ ] S19 - IAM role attached to EC2
- [ ] S20 - Docker and AWS CLI installed on EC2
- [ ] S24 - Image visible in ECR with commit SHA tag
- [ ] S25 - EC2 `docker ps` showing running container
- [ ] S26 - EC2 `/health` endpoint returns healthy
- [ ] S31 - Cleanup proof after terminating/deleting AWS resources, optional

## Email screenshots

- [ ] S27 - Success email with commit SHA, branch, image tag, EC2 target, and workflow URL
- [ ] S29 - Failure email with failed stage, commit SHA, branch, and workflow URL

## Final submission screenshots

- [ ] README.md visible in repository
- [ ] Screenshot or file containing final GitHub repository link
- [ ] VLearn submission page after upload, if available

