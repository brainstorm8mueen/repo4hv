# StreamingApp: Container Orchestration and Scaling

This repository contains the deployment assets for running the StreamingApp microservices on Amazon EKS. The application consists of a React frontend, four Node.js services, and MongoDB.

## Architecture

```text
Internet
   |
AWS Load Balancer / Ingress
   |-- /                  -> frontend:80
   |-- /api/auth          -> auth:3001
   |-- /api/streaming     -> streaming:3002
   |-- /api/admin         -> admin:3003
   |-- /api/chat and /socket.io -> chat:3004
                                      |
                         MongoDB StatefulSet:27017
```

## Repository layout

```text
Jenkinsfile
helm/streamingapp/
scripts/
docs/LEARNING_GUIDE.md
docs/SCREENSHOT_CHECKLIST.md
submission-link.txt
```

## Prerequisites

- AWS account and an IAM identity permitted to use ECR, EKS, EC2, IAM, CloudFormation, and CloudWatch
- AWS CLI, Docker, kubectl, Helm 3, and eksctl
- A fork of the StreamingApp source repository
- GitHub repository access from Jenkins

## 1. Prepare the repository

Fork the original StreamingApp repository and place the files from this kit in the root of the fork. Replace every placeholder under `REQUIRED CHANGES` before running the pipeline.

```bash
git clone https://github.com/<github-user>/StreamingApp.git
cd StreamingApp
cp -R /path/to/streamingapp-assignment-kit/* .
git add .
git commit -m "Add container orchestration deployment"
git push origin main
```

## 2. REQUIRED CHANGES

Edit `helm/streamingapp/values.yaml`:

- `global.awsAccountId`
- `global.awsRegion`
- `global.ecrRegistry`
- `ingress.host`, if using a custom DNS name
- `config.awsS3Bucket`
- `config.awsCdnUrl`, when CloudFront is used
- `secrets.jwtSecret`
- image repository names if they differ

Do not commit real AWS access keys. EKS workloads should use an IAM role for service accounts when S3 access is required. The `awsAccessKeyId` and `awsSecretAccessKey` fields are included only for assignment compatibility and should remain empty.

## 3. Create the AWS environment

```bash
export AWS_REGION=ap-south-1
export CLUSTER_NAME=streamingapp-eks
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

bash scripts/create-ecr.sh
bash scripts/create-eks.sh
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
kubectl get nodes
```

Install the AWS Load Balancer Controller by following the current AWS EKS documentation for the cluster version. The chart uses ingress class `alb` by default.

Important screenshot: capture `kubectl get nodes` with all nodes in `Ready` state.

## 4. Configure Jenkins

Create these Jenkins credentials:

- `aws-account-id`: secret text
- `aws-access-key-id`: secret text
- `aws-secret-access-key`: secret text
- `github-token`: secret text, if the repository requires it

Create a Pipeline job from SCM, point it to this repository, and set the script path to `Jenkinsfile`. Configure a GitHub webhook for automatic builds on pushes to `main`.

The pipeline validates the Helm chart, logs in to ECR, builds the five images, pushes commit-specific and `latest` tags, updates the EKS kubeconfig, deploys with Helm, and verifies the rollout.

Important screenshot: capture one successful Jenkins run showing all stages in green.

## 5. Manual image build and push

Use this when Jenkins is unavailable.

```bash
export AWS_REGION=ap-south-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REGISTRY=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
export IMAGE_TAG=1.0.0

aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$ECR_REGISTRY"

bash scripts/build-and-push.sh
```

## 6. Deploy with Helm

```bash
helm dependency update helm/streamingapp
helm lint helm/streamingapp
helm template streamingapp helm/streamingapp --namespace streamingapp > rendered.yaml

helm upgrade --install streamingapp helm/streamingapp \
  --namespace streamingapp \
  --create-namespace \
  --wait \
  --timeout 15m
```

Verify the deployment:

```bash
kubectl get pods,svc,ingress -n streamingapp
kubectl rollout status deployment/streamingapp-auth -n streamingapp
kubectl rollout status deployment/streamingapp-streaming -n streamingapp
kubectl rollout status deployment/streamingapp-admin -n streamingapp
kubectl rollout status deployment/streamingapp-chat -n streamingapp
kubectl rollout status deployment/streamingapp-frontend -n streamingapp
```

Important screenshot: capture `kubectl get pods,svc,ingress -n streamingapp` after every workload is ready and the Ingress has an address.

## 7. Reach the application

```bash
kubectl get ingress streamingapp -n streamingapp
```

If using the ALB hostname directly, copy the value shown in the `ADDRESS` column. If using a custom hostname, create the required DNS record and open the configured host in a browser.

Important screenshot: capture a successful login page or authenticated home page with the browser address visible.

## 8. Demonstrate scaling

```bash
kubectl scale deployment/streamingapp-streaming --replicas=4 -n streamingapp
kubectl rollout status deployment/streamingapp-streaming -n streamingapp
kubectl get pods -n streamingapp -l app.kubernetes.io/component=streaming
```

Important screenshot: capture the four ready streaming pods.

Return the replica count to the Helm-managed value:

```bash
helm upgrade streamingapp helm/streamingapp -n streamingapp --reuse-values
```

## 9. Demonstrate a rolling update

Build and push a new image tag, then run:

```bash
helm upgrade streamingapp helm/streamingapp \
  -n streamingapp \
  --set services.auth.image.tag=1.0.1 \
  --wait
kubectl rollout status deployment/streamingapp-auth -n streamingapp
kubectl rollout history deployment/streamingapp-auth -n streamingapp
```

The deployment strategy sets `maxUnavailable: 0` and `maxSurge: 1`.

Important screenshot: capture the successful rollout status and rollout history.

## 10. Demonstrate self-healing

```bash
POD=$(kubectl get pods -n streamingapp -l app.kubernetes.io/component=auth -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod "$POD" -n streamingapp
kubectl get pods -n streamingapp -l app.kubernetes.io/component=auth -w
```

Stop the watch after the replacement pod becomes ready.

Important screenshot: capture the replacement pod in `Running` state with a lower age than the other replica.

## 11. Monitoring and logging

```bash
bash scripts/install-cloudwatch-observability.sh
kubectl get pods -n amazon-cloudwatch
aws logs describe-log-groups --log-group-name-prefix /aws/containerinsights/$CLUSTER_NAME
```

Use CloudWatch Container Insights to review pod CPU, memory, and logs. Create an alarm for a metric relevant to the deployed workload and capture its configured state.

Important screenshot: capture the Container Insights workload view and one configured alarm.

## 12. Functional smoke tests

Complete these tests through the Ingress endpoint:

1. Register a user and log in.
2. Confirm that a JWT-backed authenticated request succeeds.
3. Upload a small video and thumbnail through the admin interface when valid S3 configuration is available.
4. Confirm that the uploaded item appears in the catalogue and plays.
5. Open two browser tabs and confirm that a chat message appears in both.
6. Delete one application pod and confirm the deployment replaces it.

Important screenshots: successful login, one completed upload, playback, and chat across two tabs. Do not include credentials or tokens in screenshots.

## Production improvements

For a production deployment, I would use separate namespaces and AWS accounts for each environment, external secret management with AWS Secrets Manager and the Secrets Store CSI Driver, IAM roles for service accounts, TLS with a managed certificate, private subnets for worker nodes and data services, a managed MongoDB service with backups, Horizontal Pod Autoscalers, PodDisruptionBudgets, NetworkPolicies, restricted security contexts, image scanning, centralized audit logging, dashboards, alarms, and tested restore procedures.

## Submission

1. Confirm that source code, Dockerfiles, Helm chart, Jenkinsfile, scripts, and documentation are committed.
2. Confirm no credentials are present in Git history.
3. Add the required screenshots under `docs/screenshots/`.
4. Replace the placeholder in `submission-link.txt` with the public GitHub repository link.
5. Submit `submission-link.txt`, or convert it to Word/PDF if the portal requires that format.
