#!/usr/bin/env bash
set -euo pipefail
: "${AWS_REGION:=ap-south-1}"
: "${CLUSTER_NAME:=streamingapp-eks}"
eksctl create cluster \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --managed \
  --nodegroup-name streamingapp-ng \
  --node-type t3.large \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 4 \
  --with-oidc
aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
