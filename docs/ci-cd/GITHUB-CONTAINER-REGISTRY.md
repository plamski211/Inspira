# Using GitHub Container Registry

This document explains how to use GitHub Container Registry (ghcr.io) as an alternative to Docker Hub for storing and retrieving container images.

## Advantages of GitHub Container Registry

1. **Integrated with GitHub Actions**: Authentication is handled automatically using the `GITHUB_TOKEN`.
2. **Free for public repositories**: Unlimited storage and bandwidth for public repositories.
3. **Private repositories**: Free storage with bandwidth limits for private repositories.
4. **No external credentials needed**: No need to set up and maintain Docker Hub credentials.

## How It Works

The workflow `.github/workflows/github-container-registry.yml` builds and pushes Docker images to GitHub Container Registry. It:

1. Uses the built-in `GITHUB_TOKEN` for authentication
2. Builds images for all microservices
3. Tags images with both `latest` and the short commit SHA
4. Pushes them to `ghcr.io/[your-username]/[service-name]`

## Accessing the Images

### Viewing in GitHub UI

1. Go to your GitHub profile
2. Click on "Packages" tab
3. You'll see all the container images you've pushed

### Pulling Images

To pull an image:

```bash
docker pull ghcr.io/[your-username]/frontend:latest
```

### Using in Kubernetes

Update your Kubernetes manifests to use the GitHub Container Registry images:

```yaml
image: ghcr.io/[your-username]/frontend:latest
```

If your repository is private, you'll need to create a Kubernetes secret with GitHub credentials:

```bash
kubectl create secret docker-registry github-container-registry \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_PAT \
  --namespace=your-namespace
```

Then reference it in your deployments:

```yaml
spec:
  template:
    spec:
      imagePullSecrets:
      - name: github-container-registry
```

## Troubleshooting

1. **Image not found**: Make sure your repository visibility settings match your package visibility.
2. **Authentication issues**: Verify that your workflow has the `packages: write` permission.
3. **Rate limiting**: If you hit rate limits, consider using a GitHub PAT with higher limits.

## Migrating from Docker Hub

To migrate existing deployments from Docker Hub to GitHub Container Registry:

1. Update all image references in your Kubernetes manifests
2. Update any scripts that pull images
3. If using Helm charts, update the image repository values 