# Screenshot Checklist

Create `docs/screenshots/` and add only evidence that directly supports the rubric.

1. `01-eks-nodes-ready.png`: `kubectl get nodes` showing Ready nodes.
2. `02-jenkins-success.png`: one complete successful pipeline with visible stage names.
3. `03-workloads.png`: `kubectl get pods,svc,ingress -n streamingapp` showing ready workloads and Ingress address.
4. `04-login.png`: successful login or authenticated page.
5. `05-upload-playback.png`: uploaded item and successful playback, when S3 is configured.
6. `06-chat-two-tabs.png`: the same chat message visible in two browser tabs.
7. `07-scale-four-pods.png`: four ready streaming pods.
8. `08-rolling-update.png`: successful rollout status and rollout history.
9. `09-self-healing.png`: replacement pod running after deletion.
10. `10-cloudwatch.png`: Container Insights workload view.
11. `11-cloudwatch-alarm.png`: configured alarm.

Before committing screenshots:

- Crop unrelated desktop content.
- Keep the command and output visible.
- Do not expose passwords, tokens, account keys, cookies, authorization headers, or private key material.
- Use readable filenames and refer to them from the README if required.
- Capture actual results from your own environment. Do not submit placeholders.
