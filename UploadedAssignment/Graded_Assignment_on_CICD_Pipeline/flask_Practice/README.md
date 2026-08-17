# CI/CD Pipeline Assignment - GitHub Actions + Docker + Amazon ECR + EC2

## 1. Project Objective

This repository contains the CI/CD assignment implementation for a Python Flask application. The pipeline uses GitHub Actions to test the application, build a Docker image, push the image to Amazon ECR, deploy the container to an EC2 instance, verify the `/health` endpoint, and send customized email notifications for success and failure.

## 2. Why GitHub Actions is selected
The assignment specifically expects a Docker image pushed to Amazon ECR and deployed on an EC2 instance. Therefore, the final pipeline uses EC2, ECR, and GitHub Actions.
For this assignment, GitHub Actions is selected instead of Jenkins because it does not require maintaining a Jenkins server. GitHub Actions can run automatically when code is pushed to the `main` branch, which matches the assignment trigger requirement.

## 3. Architecture

```text
Developer Push to GitHub main branch
        |
        v
GitHub Actions Workflow
        |
        v
Checkout Source Code
        |
        v
Install Python Dependencies
        |
        v
Run PyTest
        |
        v
Build Docker Image with Commit SHA Tag
        |
        v
Push Docker Image to Amazon ECR
        |
        v
Open temporary SSH access for GitHub runner IP
        |
        v
SSH to EC2
        |
        v
Docker login to ECR from EC2
        |
        v
Pull new image from ECR
        |
        v
Stop and remove old container
        |
        v
Run new container
        |
        v
Verify /health endpoint on EC2
        |
        v
Send customized success or failure email
        |
        v
Revoke temporary SSH rule
```

## 4. Repository structure

```text
flask_Practice/
├── app.py
├── requirements.txt
├── test_app.py
├── templates/
├── Dockerfile
├── .dockerignore
├── .env.example
├── .github/
│   └── workflows/
│       └── ci-cd.yml
├── iam-policies/
│   ├── github-actions-ecr-ec2-sg-policy.json
│   └── ec2-ecr-readonly-policy.json
└── README.md

```

## 5. Software prerequisites

Install these on the local Windows machine before starting.

| Component | Purpose | Official link |
|---|---|---|
| Git | Clone repository and push code | https://git-scm.com/install/windows |
| Python | Run Flask and PyTest locally | https://www.python.org/downloads/ |
| VS Code | Edit code and YAML files | https://code.visualstudio.com/ |
| Docker Desktop | Build and test container locally | https://docs.docker.com/desktop/setup/install/windows-install/ |
| AWS CLI | Optional local AWS validation | https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html |
| GitHub account | Source control and CI/CD | https://github.com/ |
| AWS account | ECR and EC2 | https://aws.amazon.com/ |

```bash
git --version
python --version
docker --version
aws --version
"C:\Program Files\Microsoft VS Code\bin\code.cmd" --version
```
## ![Screenshot](reference/Screenshot_S01.png)


## 6. Fork and clone the assignment repository

Clone the source repository:
```bash
git clone https://github.com/mohanDevOps-arch/flask_Practice.git
cd flask_Practice
```

## 7. Add or confirm `/health` endpoint

Add the following route in `app.py`. Place it near the other Flask routes.

```python
@app.route('/health')
def health():
    return {'status': 'healthy'}, 200
```

If the application already uses MongoDB and you want to check MongoDB connectivity, you may return `healthy` only after a simple database ping. For assignment practice, the simple route above is acceptable if local MongoDB is not configured.

Run the app locally and open:

Install dependencies:
```bash
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

Run:
```bash
python app.py
```

```text
http://localhost:5000/health
```

Expected output:

```json
{"status":"healthy"}
```
## ![Screenshot](reference/Screenshot_S02.png)

## 8. Python test setup

Install dependencies locally:

```bash
python -m pip install --upgrade pip
pip install -r requirements.txt
pip install pytest
```

If `pytest` is not already in `requirements.txt`, add it:

```text
pytest
```

Create or update `test_app.py`:

```python
from app import app


def test_home_route():
    client = app.test_client()
    response = client.get('/')
    assert response.status_code in [200, 302]


def test_health_route():
    client = app.test_client()
    response = client.get('/health')
    assert response.status_code == 200
    assert b'healthy' in response.data
```

Run tests:

```bash
pytest -v
```

## ![Screenshot](reference/Screenshot_S03.png)


## 9. Dockerfile

Create `Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
```

## 10. Ignore Files

Create `.dockerignore`:

```text
.git
.github

venv/
.venv/

__pycache__/
.pytest_cache/
*.pyc

.env
*.pem

screenshots/

.vscode/

Thumbs.db
.DS_Store
```

# Note: Simlarly created .gitignore
```text
# Virtual Environments
venv/
.venv/

# Python
__pycache__/
*.pyc
.pytest_cache/

# Environment files
.env

# AWS Keys
*.pem

# Local screenshots
screenshots/

# VS Code
.vscode/

# OS files
Thumbs.db
.DS_Store
```

## 11. Local Docker build and run

Build:

```bash
docker build -t student-registration-app:local .
```

Run:

```bash
docker run --env-file .env -p 5000:5000 student-registration-app:local
```

Open:

```text
http://localhost:5000/health
```

## ![Screenshot](reference/Screenshot_S04.png)


Open:

```text
http://localhost:5000
```

## ![Screenshot](reference/Screenshot_S05.png)


## 12. AWS resources required

Create AWS resources only after local testing is complete to reduce cost.

Required resources:

1. Amazon ECR repository
2. EC2 Ubuntu instance
3. IAM role attached to EC2 with ECR read-only permissions (policies attached)
4. IAM user or credentials for GitHub Actions with ECR push and temporary security group update permissions
5. Security group for EC2

## 13. Create Amazon ECR repository

Repository name:

```text
student-registration-app
```

## ![Screenshot](reference/Screenshot_S06.png)


## 14. Create EC2 instance

Recommended assignment setup:

```text
AMI: Ubuntu Server 24.04 LTS
Instance type: t3.micro or free-tier eligible option if available
Storage: default only
Public IP: enabled
```

Security group inbound rules:

```text
SSH 22: temporary GitHub runner IP added by pipeline
HTTP app 5000: your public IP only for browser screenshot
```

Important: If port 22 is only open to your home/office IP, GitHub Actions cannot SSH to EC2 because GitHub Actions uses a cloud runner with a different dynamic public IP. This package uses a safer approach: the workflow temporarily adds the current GitHub runner public IP to the EC2 security group before deployment and removes it at the end.

## ![Screenshot](reference/Screenshot_S07.png)


## ![Screenshot](reference/Screenshot_S08.png)


## 15. Attach IAM role to EC2

Attach an EC2 instance role with ECR read-only permissions. Use the policy from:

```text
iam-policies/ec2-ecr-readonly-policy.json
#Note added in iam-policies\ec2-ecr-readonly-policy.json
```

## ![Screenshot](reference/Screenshot_S09.png)


## 16. Install Docker and AWS CLI on EC2

SSH to EC2:

```bash
ssh -i mueenab.pem ubuntu@13.223.243.8
```

Install Docker:

```bash
sudo apt update
sudo apt install docker.io unzip curl -y
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu
```

Install AWS CLI v2:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

Log out and log back in so the Docker group change applies:

```bash
exit
ssh -i your-key.pem ubuntu@EC2_PUBLIC_IP
```

Verify:

```bash
docker --version
aws --version
```

## ![Screenshot](reference/Screenshot_S10.png)


## 17. GitHub Actions secrets

Go to:

```text
GitHub repository > Settings > Secrets and variables > Actions > New repository secret
```

Create these secrets:

```text
MONGO_URI
SECRET_KEY
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
AWS_ACCOUNT_ID
ECR_REPOSITORY
EC2_HOST
EC2_USER
EC2_SSH_KEY
EC2_SECURITY_GROUP_ID
SMTP_HOST
SMTP_PORT
SMTP_USERNAME
SMTP_PASSWORD
EMAIL_FROM
EMAIL_TO
```

Recommended values:

```text
AWS_REGION = your AWS region, for example us-east-1
ECR_REPOSITORY = student-registration-app
EC2_USER = ubuntu
EC2_HOST = EC2 public IPv4 address
EC2_SECURITY_GROUP_ID = security group ID attached to EC2, for example sg-xxxxxxxx
SMTP_PORT = 587
```

Do not commit secret values to GitHub.

## ![Screenshot](reference/Screenshot_S11.png)


## 18. GitHub Actions workflow
I have created new repo for this but added into assigment with copy but if you need to review this you can check below as well
```
https://github.com/brainstorm8mueen/student-registration-app
```
Create:

```text
.github/workflows/ci-cd.yml
```

Use the provided workflow file from this package.

The workflow does the following:

1. Runs on push to `main`
2. Installs Python dependencies
3. Runs PyTest
4. Builds Docker image with commit SHA
5. Pushes image to ECR
6. Gets GitHub runner public IP
7. Temporarily opens SSH access to EC2 security group
8. SSHs into EC2
9. Pulls the image from ECR
10. Replaces the old container
11. Checks `/health`
12. Sends success email
13. Sends failure email when any stage fails
14. Revokes temporary SSH access

## ![Screenshot](reference/Screenshot_S12.png)


## 19. Push code to main branch

```bash
git add .
git commit -m "Add CI/CD pipeline assignment files"
git push origin main
```

## ![Screenshot](reference/Screenshot_S13.png)



## ![Screenshot](reference/Screenshot_S14.png)


## 20. Verify image in ECR

Go to Amazon ECR and open the repository.

You should see an image tag matching the Git commit SHA.

## 21. Verify container on EC2

SSH to EC2:

```bash
ssh -i your-key.pem ubuntu@EC2_PUBLIC_IP
```

Run:

```bash
docker ps
```

Expected container name:

```text
flask-student-app
```

## ![Screenshot](reference/Screenshot_S15.png)

## 22. Verify health check on EC2

On EC2:

```bash
curl http://localhost:5000/health
```

Expected:

```json
{"status":"healthy"}
```

From your browser, if port 5000 allows your IP:

```text
http://EC2_PUBLIC_IP:5000/health
```

## ![Screenshot](reference/Screenshot_S16.png)


## 23. Success email

The success email should show:

- Success indicator
- Commit SHA
- Branch
- Docker image tag
- ECR image URI
- EC2 target
- Workflow run link

## ![Screenshot](reference/Screenshot_S17.png)


## 24. Intentional failure test

For the required failure screenshot, temporarily add a failing test:

```python
def test_intentional_failure_for_assignment():
    assert False
```

Commit and push:

```bash
git add test_app.py
git commit -m "Intentional failing test for assignment evidence"
git push origin main
```
The pipeline should stop at the test stage and send a failure email.
FYI: Above is just example how to fail the pipleline, but I have failed incident before success so adding for referance

## ![Screenshot](reference/Screenshot_S18.png)


## ![Screenshot](reference/Screenshot_S19.png)


## 25. Manual deployment if pipeline is unavailable

SSH to EC2:

```bash
ssh -i your-key.pem ubuntu@EC2_PUBLIC_IP
```

Login to ECR:

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 960346386867.dkr.ecr.us-east-1.amazonaws.com
```

Pull image:

```bash
docker pull 960346386867.dkr.ecr.us-east-1.amazonaws.com/student-registration-app:7ae11e9af33fe9ff4ec67d83eb893ee3d3137bb7
```

Replace container:

```bash
docker stop flask-student-app || true
docker rm flask-student-app || true
docker run -d --name flask-student-app --restart unless-stopped -p 5000:5000 -e MONGO_URI="mongodb+srv://mueenab:Passw0rd123@mueenb-cluster.p6fijvk.mongodb.net/mbtest?retryWrites=true&w=majority" 960346386867.dkr.ecr.us-east-1.amazonaws.com/student-registration-app:7ae11e9af33fe9ff4ec67d83eb893ee3d3137bb7
```

Verify:

```bash
curl http://localhost:5000/health
```

## ![Screenshot](reference/Screenshot_S20.png)


## 26. Cleanup to avoid AWS cost

After all screenshots and submission evidence are collected:

1. Terminate EC2 instance
2. Deleted unused EBS volumes
3. Deleted IAM role
4. Deleted ECR repository and images
5. Deleted IAM access keys used for GitHub Actions
6. Confirmed snapshots if any were created
7. Confirmed no Elastic IP is allocated

## Before_Deleted
## ![Screenshot](reference/Screenshot_S21.png)


## After_Deleted
## ![Screenshot](reference/Screenshot_S22.png)


## 27. Final submission
Done by uploading Graded_Assignment_on_CICD_Pipeline.txt at VLearn Portal as submission with this current repo URL.
Also adding GitHub Actions workflow repo: https://github.com/brainstorm8mueen/student-registration-app

## Referance
- https://github.com/mohanDevOps-arch/flask_Practice
- AI use by Copilot
- Internet help by Google