#!/usr/bin/env bash
set -euo pipefail
: "${ECR_REGISTRY:?Set ECR_REGISTRY}"
: "${IMAGE_TAG:?Set IMAGE_TAG}"

declare -A CONTEXTS=(
  [streaming-auth]="backend/authService"
  [streaming-streaming]="backend"
  [streaming-admin]="backend"
  [streaming-chat]="backend"
  [streaming-frontend]="frontend"
)
declare -A DOCKERFILES=(
  [streaming-auth]="backend/authService/Dockerfile"
  [streaming-streaming]="backend/streamingService/Dockerfile"
  [streaming-admin]="backend/adminService/Dockerfile"
  [streaming-chat]="backend/chatService/Dockerfile"
  [streaming-frontend]="frontend/Dockerfile"
)

for repository in streaming-auth streaming-streaming streaming-admin streaming-chat streaming-frontend; do
  image="$ECR_REGISTRY/$repository"
  docker build -f "${DOCKERFILES[$repository]}" -t "$image:$IMAGE_TAG" -t "$image:latest" "${CONTEXTS[$repository]}"
  docker push "$image:$IMAGE_TAG"
  docker push "$image:latest"
done
