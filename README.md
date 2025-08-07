# Useless Box

A containerized application built with Python, deployed on Kubernetes.

## Overview

Useless Box is a containerized application that demonstrates modern deployment practices using Docker, Kubernetes, and GitHub Actions for CI/CD.

## Tech Stack

- Python
- Docker
- Kubernetes
- GitHub Actions

## Project Structure

```
useless-box/
├── Dockerfile              # Container definition
├── .github/
│   └── workflows/         
│       └── docker-build-push.yaml  # CI/CD pipeline
└── k8s/                    # Kubernetes manifests
    ├── deployment.yaml     # Deployment configuration
    └── service.yaml        # Service configuration
```

## Getting Started

### Prerequisites

- Docker
- Kubernetes cluster
- kubectl configured
- GitHub account
- DockerHub account

### Local Development

1. Build the Docker image locally:
```bash
docker build -t useless-box .
docker run -p 5000:5000 useless-box
```

### Deployment

#### Docker

The application is automatically built and pushed to DockerHub via GitHub Actions when changes are pushed to the main branch.

Image available at: `rmnobarra/useless-box`

#### Kubernetes

Deploy to Kubernetes cluster:

```bash
kubectl apply -f k8s/
```

This will create:
- A deployment with 2 replicas
- A ClusterIP service exposing port 80

### CI/CD

The project uses GitHub Actions for continuous integration and delivery:
- Automatically builds Docker image
- Pushes to DockerHub with tags:
  - `latest`
  - Git commit SHA for versioning

### Configuration

#### Resource Limits

The application is configured with the following resource limits in Kubernetes:

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```

### Environment Variables

[List any environment variables that need to be configured]

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Security

Remember to:
- Never commit sensitive information
- Use GitHub Secrets for DockerHub credentials
- Keep dependencies updated

## Metrics

