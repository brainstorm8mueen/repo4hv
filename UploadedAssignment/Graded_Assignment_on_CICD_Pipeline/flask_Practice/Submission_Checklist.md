# Submission Checklist - CI/CD Assignment

Before submitting to VLearn, confirm all items below.

## Repository contents

- [ ] Flask application is present
- [ ] `/health` route is added
- [ ] `requirements.txt` is present
- [ ] `test_app.py` is present
- [ ] `Dockerfile` is present
- [ ] `.dockerignore` is present
- [ ] `.github/workflows/ci-cd.yml` is present
- [ ] `README.md` is updated
- [ ] IAM policy examples are included or documented
- [ ] No `.env`, `.pem`, AWS keys, SMTP passwords, or MongoDB connection secrets are committed

## Pipeline requirements

- [ ] Workflow triggers on push to `main`
- [ ] Checkout stage works
- [ ] Install stage works
- [ ] Test stage runs PyTest
- [ ] Pipeline stops if test fails
- [ ] Docker image builds successfully
- [ ] Docker image is tagged with commit SHA
- [ ] Docker image pushes to Amazon ECR
- [ ] Pipeline connects to EC2 using SSH
- [ ] EC2 pulls the latest image from ECR
- [ ] Existing container is stopped and removed
- [ ] New container runs with `--restart unless-stopped`
- [ ] `/health` check gates deployment success
- [ ] Success email is customized
- [ ] Failure email is customized and shows failed stage

## Screenshot evidence

- [ ] Full successful pipeline run
- [ ] Success email received
- [ ] Intentional failed run
- [ ] Failure email received
- [ ] ECR pushed image
- [ ] EC2 running container
- [ ] Health check output
- [ ] README documentation

## Cost cleanup

- [ ] EC2 instance terminated after screenshots
- [ ] ECR repository deleted after screenshots
- [ ] Unused volumes deleted
- [ ] Snapshots deleted if any exist
- [ ] Elastic IP released if allocated
- [ ] IAM access keys deleted if no longer needed

## VLearn submission text

Use this format:

```text
CI/CD Pipeline Assignment Submission

GitHub Repository Link:
https://github.com/YOUR_GITHUB_USERNAME/flask_Practice

Submitted by:
YOUR_NAME
```

