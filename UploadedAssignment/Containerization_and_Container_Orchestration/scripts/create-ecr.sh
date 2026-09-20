#!/usr/bin/env bash
set -euo pipefail
: "${AWS_REGION:=ap-south-1}"
for repository in streaming-auth streaming-streaming streaming-admin streaming-chat streaming-frontend; do
  aws ecr describe-repositories --repository-names "$repository" --region "$AWS_REGION" >/dev/null 2>&1 || \
  aws ecr create-repository --repository-name "$repository" --image-scanning-configuration scanOnPush=true --region "$AWS_REGION"
done
