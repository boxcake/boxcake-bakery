#!/bin/bash
set -e

# Configuration
IMAGE_NAME="portainer-config"
IMAGE_TAG="latest"
REGISTRY_HOST="${1:-registry-service:5000}"

echo "🔨 Building portainer-config image..."

# Build the image
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

# Tag for local registry
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY_HOST}/${IMAGE_NAME}:${IMAGE_TAG}

echo "📤 Pushing to local registry at ${REGISTRY_HOST}..."

# Push to local registry
docker push ${REGISTRY_HOST}/${IMAGE_NAME}:${IMAGE_TAG}

echo "✅ Image pushed successfully!"
echo "   📦 Image: ${REGISTRY_HOST}/${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "Update your Terraform configuration to use:"
echo "   image = \"${REGISTRY_HOST}/${IMAGE_NAME}:${IMAGE_TAG}\""