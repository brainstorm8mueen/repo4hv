# Learning Guide: Every Action Explained

This guide explains the purpose of each stage so the deployment can be reproduced and troubleshot independently.

## 1. Source control

A fork provides an editable copy of the application while retaining a link to the upstream project. Each deployment should be tied to a commit. The Jenkinsfile uses the short Git commit SHA as an image tag, which makes it possible to identify exactly which source version is running.

Useful commands:

```bash
git remote -v
git status
git log --oneline -5
git remote add upstream https://github.com/UnpredictablePrashant/StreamingApp.git
git fetch upstream
git merge upstream/main
```

## 2. Container images

Each service has its own image because each is deployed, scaled, and updated independently. A Docker build context determines which files Docker can access. The streaming, admin, and chat builds use `backend` as their context so shared service files can be included if required by their Dockerfiles.

The image tag should be immutable. `latest` is convenient for inspection, but a version or commit SHA is better for deployments and rollback.

Inspect an image:

```bash
docker image ls
docker history <image>
docker inspect <image>
docker run --rm -p 3001:3001 --env-file backend/authService/.env <auth-image>
```

## 3. Amazon ECR

ECR is the private image registry. Kubernetes nodes need permission to pull images. EKS worker node roles normally receive ECR pull permissions. Jenkins needs permission to authenticate and push.

ECR login tokens are short-lived, so the pipeline logs in during each build rather than storing a Docker password.

```bash
aws ecr describe-repositories --region "$AWS_REGION"
aws ecr list-images --repository-name streaming-auth --region "$AWS_REGION"
```

## 4. EKS

EKS manages the Kubernetes control plane. Worker nodes run the pods. `eksctl` creates the cluster, node group, IAM roles, networking integration, and kubeconfig connection.

```bash
kubectl config current-context
kubectl cluster-info
kubectl get nodes -o wide
```

If `kubectl` points to the wrong cluster, update kubeconfig and verify the context before deploying.

## 5. Kubernetes objects

### Deployment

A Deployment manages stateless pods. It maintains the requested replica count and creates ReplicaSets during rolling updates. The chart defines resource requests and limits, health probes, and a zero-unavailable rolling strategy.

### Service

A ClusterIP Service provides a stable internal DNS name even when pod IPs change. For example, the auth service is reachable inside the namespace as `streamingapp-auth:3001`.

### ConfigMap and Secret

A ConfigMap holds non-sensitive settings. A Secret holds sensitive values, but base64 encoding is not encryption. Production secrets should come from a dedicated secret manager and should not be stored in Git.

### StatefulSet and PVC

MongoDB uses a StatefulSet because it needs a stable identity and persistent volume claim. The PVC keeps the database files when the MongoDB pod is recreated. For production, a managed database and tested backups are safer than a single in-cluster database pod.

### Ingress

Ingress defines external HTTP routing. The AWS Load Balancer Controller interprets the Ingress and provisions an Application Load Balancer. Routes send frontend and API traffic to the matching ClusterIP service.

## 6. Helm

Helm packages Kubernetes manifests as templates. `values.yaml` separates configuration from object structure. This allows the same chart to deploy different image tags, replica counts, hosts, and resource settings.

```bash
helm lint helm/streamingapp
helm template streamingapp helm/streamingapp --namespace streamingapp
helm upgrade --install streamingapp helm/streamingapp -n streamingapp --create-namespace
helm history streamingapp -n streamingapp
helm rollback streamingapp 1 -n streamingapp
```

Always inspect `helm template` output before applying a major change.

## 7. Health probes

A readiness probe controls whether a pod receives Service traffic. A liveness probe restarts a container that is stuck. A startup probe gives a slow application time to start before liveness checks begin.

The default chart uses TCP socket probes because the source application does not define a dedicated common health endpoint for every service in the assignment materials. If a service has an HTTP health path, configure `probePath` for that service and change the template to use `httpGet`.

Troubleshooting:

```bash
kubectl describe pod <pod> -n streamingapp
kubectl logs <pod> -n streamingapp --previous
kubectl get events -n streamingapp --sort-by=.lastTimestamp
```

## 8. Scaling

Manual scaling changes the desired replica count. Helm may restore the value from `values.yaml` during the next upgrade. HPA automates replica changes from metrics, but it requires resource requests and a metrics provider.

```bash
kubectl scale deployment/streamingapp-streaming --replicas=4 -n streamingapp
kubectl get deployment streamingapp-streaming -n streamingapp
kubectl top pods -n streamingapp
```

## 9. Rolling updates and rollback

During a rolling update, Kubernetes creates new pods before removing old ones. `maxUnavailable: 0` keeps the current ready capacity, and `maxSurge: 1` permits one additional pod during the rollout.

```bash
kubectl rollout status deployment/streamingapp-auth -n streamingapp
kubectl rollout history deployment/streamingapp-auth -n streamingapp
kubectl rollout undo deployment/streamingapp-auth -n streamingapp
```

A successful rollout only confirms Kubernetes readiness. Functional smoke tests are still required.

## 10. Jenkins pipeline

The pipeline stages are:

1. Checkout: obtains the exact commit.
2. Validate: runs Helm lint and template rendering.
3. ECR login: obtains a temporary registry token.
4. Build and push: builds all five images and pushes commit and `latest` tags.
5. Configure EKS: creates the kubeconfig entry.
6. Deploy: runs `helm upgrade --install` and injects the commit tag.
7. Verify: waits for each Deployment rollout and lists resources.

Credentials are read from Jenkins Credentials and are not written into the Jenkinsfile.

## 11. Monitoring and logging

The CloudWatch Observability add-on deploys agents that collect Container Insights telemetry. Logs and metrics should answer:

- Are pods restarting?
- Is CPU or memory approaching limits?
- Are requests failing?
- Did a rollout change error rates?
- Is a node short of capacity?

An alarm should have a clear owner, threshold, evaluation period, and response action.

## 12. Common failures

### ImagePullBackOff

Check image name, tag, registry region, ECR permissions, and whether the image exists.

```bash
kubectl describe pod <pod> -n streamingapp
aws ecr describe-images --repository-name streaming-auth --region "$AWS_REGION"
```

### CrashLoopBackOff

Check current and previous logs, environment variables, MongoDB connectivity, and port configuration.

```bash
kubectl logs <pod> -n streamingapp
kubectl logs <pod> -n streamingapp --previous
```

### Pending pod

Check node capacity, PVC binding, taints, affinity rules, and resource requests.

```bash
kubectl describe pod <pod> -n streamingapp
kubectl get pvc -n streamingapp
kubectl describe node <node>
```

### Ingress has no address

Check the AWS Load Balancer Controller, its logs, subnet tags, ingress class, security groups, and AWS permissions.

```bash
kubectl get pods -n kube-system | grep aws-load-balancer-controller
kubectl describe ingress streamingapp -n streamingapp
```

### API works internally but not through Ingress

Compare the Ingress path to the application's route prefix. Test the ClusterIP service from a temporary pod.

```bash
kubectl run curl --rm -it --image=curlimages/curl -- sh
```

## 13. Cleanup

Cleanup prevents ongoing AWS charges. Export the same names used during creation.

```bash
helm uninstall streamingapp -n streamingapp
kubectl delete namespace streamingapp
bash scripts/delete-eks.sh
```

Delete ECR repositories only after confirming the images are no longer required.
