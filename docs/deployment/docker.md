# Deploying with Docker

This guide shows how to deploy Pull Request Size using Docker.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed
- Your GitHub App credentials (APP_ID, WEBHOOK_SECRET, PRIVATE_KEY)
- A server or cloud platform to run Docker containers

## Quick Start

### Using Docker Run

```bash
# Build the image
docker build -t pull-request-size .

# Run the container
docker run -d \
  --name pr-size \
  -p 3000:3000 \
  -e APP_ID=123456 \
  -e WEBHOOK_SECRET=your_webhook_secret \
  -e PRIVATE_KEY="$(cat your-private-key.pem)" \
  pull-request-size

# View logs
docker logs -f pr-size
```

### Using Docker Compose

1. Create a `.env` file:
```bash
APP_ID=123456
WEBHOOK_SECRET=your_webhook_secret
PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\nYOUR_KEY_HERE\n-----END RSA PRIVATE KEY-----"
```

2. Start the container:
```bash
docker-compose up -d

# View logs
docker-compose logs -f
```

## Production Deployment

### Option 1: Deploy to a VPS (DigitalOcean, Linode, etc.)

1. SSH into your server:
```bash
ssh user@your-server-ip
```

2. Install Docker (if not already installed):
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

3. Clone your repository:
```bash
git clone https://github.com/YOUR_USERNAME/pull-request-size.git
cd pull-request-size
```

4. Create `.env` file with your credentials

5. Run with Docker Compose:
```bash
docker-compose up -d
```

6. Set up a reverse proxy (Nginx or Caddy) to handle HTTPS:

**Using Caddy (easiest for HTTPS):**

```bash
# Install Caddy
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy
```

Create `/etc/caddy/Caddyfile`:
```
your-domain.com {
    reverse_proxy localhost:3000
}
```

Reload Caddy:
```bash
sudo systemctl reload caddy
```

### Option 2: Deploy to AWS ECS (Elastic Container Service)

1. Build and push to ECR:
```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

# Create repository
aws ecr create-repository --repository-name pull-request-size

# Build and tag
docker build -t pull-request-size .
docker tag pull-request-size:latest YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/pull-request-size:latest

# Push
docker push YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/pull-request-size:latest
```

2. Create ECS task definition (JSON):
```json
{
  "family": "pull-request-size",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "pull-request-size",
      "image": "YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/pull-request-size:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "APP_ID",
          "value": "123456"
        },
        {
          "name": "NODE_ENV",
          "value": "production"
        }
      ],
      "secrets": [
        {
          "name": "WEBHOOK_SECRET",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:webhook-secret"
        },
        {
          "name": "PRIVATE_KEY",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:private-key"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/pull-request-size",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512"
}
```

3. Create and run ECS service

### Option 3: Deploy to Google Cloud Run

```bash
# Build and push to Google Container Registry
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/pull-request-size

# Deploy to Cloud Run
gcloud run deploy pull-request-size \
  --image gcr.io/YOUR_PROJECT_ID/pull-request-size \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars APP_ID=123456,WEBHOOK_SECRET=your_secret \
  --set-secrets PRIVATE_KEY=pr-size-key:latest
```

### Option 4: Deploy to Azure Container Instances

```bash
# Create resource group
az group create --name pr-size-rg --location eastus

# Create container registry
az acr create --resource-group pr-size-rg --name prsizeregistry --sku Basic

# Login to ACR
az acr login --name prsizeregistry

# Build and push
docker tag pull-request-size prsizeregistry.azurecr.io/pull-request-size:latest
docker push prsizeregistry.azurecr.io/pull-request-size:latest

# Deploy to ACI
az container create \
  --resource-group pr-size-rg \
  --name pr-size \
  --image prsizeregistry.azurecr.io/pull-request-size:latest \
  --dns-name-label pr-size-app \
  --ports 3000 \
  --environment-variables APP_ID=123456 \
  --secure-environment-variables \
    WEBHOOK_SECRET=your_secret \
    PRIVATE_KEY="$(cat your-private-key.pem)"
```

## Docker Compose for Production

Enhanced `docker-compose.yml` with logging and restart policies:

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    env_file:
      - .env
    restart: unless-stopped
    environment:
      - NODE_ENV=production
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/probot"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    networks:
      - pr-size-network

  # Optional: Add Nginx reverse proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - app
    restart: unless-stopped
    networks:
      - pr-size-network

networks:
  pr-size-network:
    driver: bridge
```

## Monitoring and Logs

### View logs
```bash
# Docker run
docker logs -f pr-size

# Docker Compose
docker-compose logs -f

# Last 100 lines
docker logs --tail 100 pr-size
```

### Container stats
```bash
docker stats pr-size
```

### Health check
```bash
docker inspect --format='{{.State.Health.Status}}' pr-size
```

## Updating

```bash
# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Troubleshooting

### Container exits immediately
```bash
# Check logs
docker logs pr-size

# Run interactively for debugging
docker run -it --rm \
  -e APP_ID=123456 \
  -e WEBHOOK_SECRET=test \
  -e PRIVATE_KEY="$(cat your-private-key.pem)" \
  pull-request-size
```

### Port already in use
```bash
# Change the port mapping
docker run -d -p 8080:3000 ... pull-request-size
```

### Private key format issues
```bash
# Verify the key in the container
docker exec pr-size printenv PRIVATE_KEY
```

## Security Best Practices

1. **Use secrets management**:
   - Don't include secrets in the image
   - Use Docker secrets or external secret managers

2. **Run as non-root user**:
```dockerfile
FROM node:18-alpine
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001
USER nodejs
```

3. **Keep images updated**:
```bash
docker pull node:18-alpine
docker-compose build --no-cache
```

4. **Scan for vulnerabilities**:
```bash
docker scan pull-request-size
```

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Docker Hub](https://hub.docker.com/)
