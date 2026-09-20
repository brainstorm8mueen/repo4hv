#!/usr/bin/env bash
set -euo pipefail
: "${AWS_REGION:=ap-south-1}"
: "${CLUSTER_NAME:=streamingapp-eks}"
eksctl delete cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --wait
