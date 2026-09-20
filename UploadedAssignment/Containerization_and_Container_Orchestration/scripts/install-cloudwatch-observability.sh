#!/usr/bin/env bash
set -euo pipefail
: "${AWS_REGION:=ap-south-1}"
: "${CLUSTER_NAME:=streamingapp-eks}"
aws eks create-addon \
  --cluster-name "$CLUSTER_NAME" \
  --addon-name amazon-cloudwatch-observability \
  --region "$AWS_REGION" \
  --resolve-conflicts OVERWRITE || \
aws eks update-addon \
  --cluster-name "$CLUSTER_NAME" \
  --addon-name amazon-cloudwatch-observability \
  --region "$AWS_REGION" \
  --resolve-conflicts OVERWRITE
