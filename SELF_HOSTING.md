# Self-Hosting Guide

This guide will help you self-host your own instance of the Pull Request Size GitHub App.

## Prerequisites

- Node.js 16.0.0 or higher
- npm or yarn package manager
- A GitHub account (personal or organization)
- Access to a hosting platform (see deployment options below)

## Step 1: Create a GitHub App

1. Go to your GitHub account settings:
   - For personal account: https://github.com/settings/apps
   - For organization: https://github.com/organizations/YOUR_ORG/settings/apps

2. Click **New GitHub App**

3. Fill in the GitHub App details:
   - **GitHub App name**: Choose a unique name (e.g., "My PR Size Bot")
   - **Homepage URL**: Your app's homepage (can be your repo URL)
   - **Webhook URL**: This will be your deployed app URL + `/api/github/webhooks`
     - For example: `https://your-app.herokuapp.com/api/github/webhooks`
     - For AWS Lambda: `https://your-api-id.execute-api.region.amazonaws.com/api/github/webhooks`
     - You can update this later after deployment
   - **Webhook Secret**: Generate a random secret string (save this for later)
     - You can generate one with: `ruby -rsecurerandom -e 'puts SecureRandom.hex(20)'`
     - Or online at: https://randomkeygen.com/

4. Configure **Permissions & events**:
   
   **Repository permissions:**
   - Pull requests: **Read & write**
   - Metadata: **Read-only**
   - Single file: **Read-only** (Path: `.gitattributes`)
   
   **Subscribe to events:**
   - [x] Pull request

5. **Where can this GitHub App be installed?**
   - Choose "Any account" if you want others to use it
   - Choose "Only on this account" for private use

6. Click **Create GitHub App**

7. **Generate a Private Key**:
   - After creating the app, scroll down to "Private keys"
   - Click "Generate a private key"
   - A `.pem` file will be downloaded - **keep this safe!**

8. **Note your App ID**:
   - You'll see the App ID near the top of the page - save this

## Step 2: Install the GitHub App

1. On your GitHub App's page, click **Install App** in the left sidebar
2. Select the account/organization where you want to install it
3. Choose either:
   - **All repositories** - to monitor all repos
   - **Only select repositories** - to choose specific repos
4. Click **Install**

## Step 3: Configure Environment Variables

Create a `.env` file in your project root (copy from `.env.example`):

```bash
cp .env.example .env
```

Edit `.env` and fill in the values:

```bash
# Your GitHub App ID (from Step 1)
APP_ID=123456

# Webhook secret you created (from Step 1)
WEBHOOK_SECRET=your_webhook_secret_here

# Private key from the .pem file (from Step 1)
# For the private key, you have two options:

# Option 1: Inline (base64 encoded) - recommended for cloud platforms
PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\nYOUR_PRIVATE_KEY_CONTENT_HERE\n-----END RSA PRIVATE KEY-----"

# Option 2: Path to .pem file - for local development
# PRIVATE_KEY_PATH=./your-app-name.2024-10-27.private-key.pem

# Optional: Sentry DSN for error tracking (remove if not using Sentry)
# SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
```

**Important**: To format your private key for the `.env` file:

**Easy way - use the provided script:**
```bash
./scripts/format-private-key.sh your-private-key.pem
```

**Manual way:**
```bash
# Read your .pem file and format it as a single line
cat your-private-key.pem | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}'
```

Or use base64 encoding:
```bash
cat your-private-key.pem | base64
```

## Step 4: Choose a Deployment Method

**Not sure which deployment option to choose?** See the [Deployment Comparison Guide](docs/DEPLOYMENT_COMPARISON.md) for detailed comparisons of all options.

### Option A: Local Development/Testing

Perfect for testing and development:

```bash
# Install dependencies
npm install

# Run the app
npm start
```

The app will run on `http://localhost:3000`. 

To receive webhooks locally, use a tool like [smee.io](https://smee.io):

```bash
# Install smee-client
npm install -g smee-client

# Start smee (get your webhook URL from smee.io)
smee --url https://smee.io/YOUR_UNIQUE_ID --path /api/github/webhooks --port 3000
```

Update your GitHub App's webhook URL to your smee.io URL.

### Option B: AWS Lambda (Serverless)

This repository includes pre-configured AWS Lambda deployment:

1. Install AWS CLI and configure credentials:
```bash
aws configure
```

2. Update `serverless.yml` with your settings:
```yaml
org: your-org-name
app: your-app-name
service: your-service-name
```

3. Deploy:
```bash
npm install
npx serverless deploy
```

4. Note the endpoint URL from the output and update your GitHub App's webhook URL

**Environment Variables for AWS:**
- Set these in `serverless.yml` under `provider.environment`
- Or use AWS Systems Manager Parameter Store / Secrets Manager

### Option C: Heroku

Deploy to Heroku with these steps:

1. Create a new Heroku app:
```bash
heroku create your-app-name
```

2. Set environment variables:
```bash
heroku config:set APP_ID=your_app_id
heroku config:set WEBHOOK_SECRET=your_webhook_secret
heroku config:set PRIVATE_KEY="$(cat your-private-key.pem)"
# Optional:
heroku config:set SENTRY_DSN=your_sentry_dsn
```

3. Create a `Procfile` in your project root:
```
web: npm start
```

4. Deploy:
```bash
git push heroku main
```

5. Update your GitHub App's webhook URL to: `https://your-app-name.herokuapp.com/api/github/webhooks`

### Option D: Docker

1. Create a `Dockerfile` in your project root:
```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

2. Build and run:
```bash
# Build the image
docker build -t pull-request-size .

# Run the container
docker run -d \
  -p 3000:3000 \
  -e APP_ID=your_app_id \
  -e WEBHOOK_SECRET=your_webhook_secret \
  -e PRIVATE_KEY="$(cat your-private-key.pem)" \
  pull-request-size
```

3. For docker-compose, create `docker-compose.yml`:
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
```

Run with:
```bash
docker-compose up -d
```

### Option E: Vercel

1. Install Vercel CLI:
```bash
npm i -g vercel
```

2. Create `vercel.json`:
```json
{
  "version": 2,
  "builds": [
    {
      "src": "src/index.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/api/github/webhooks",
      "dest": "src/index.js"
    }
  ]
}
```

3. Deploy:
```bash
vercel
```

4. Set environment variables in Vercel dashboard or via CLI:
```bash
vercel env add APP_ID
vercel env add WEBHOOK_SECRET
vercel env add PRIVATE_KEY
```

### Option F: Google Cloud Run

1. Create a `Dockerfile` (see Docker section above)

2. Build and push to Google Container Registry:
```bash
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/pull-request-size
```

3. Deploy to Cloud Run:
```bash
gcloud run deploy pull-request-size \
  --image gcr.io/YOUR_PROJECT_ID/pull-request-size \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars APP_ID=your_app_id,WEBHOOK_SECRET=your_webhook_secret \
  --set-secrets PRIVATE_KEY=your_secret_name:latest
```

### Option G: Azure Web App

1. Create a new Web App in Azure Portal (Node.js runtime)

2. Configure deployment:
```bash
az webapp deployment source config-local-git --name your-app-name --resource-group your-resource-group
```

3. Set environment variables:
```bash
az webapp config appsettings set --name your-app-name --resource-group your-resource-group --settings APP_ID=your_app_id WEBHOOK_SECRET=your_webhook_secret PRIVATE_KEY="$(cat your-private-key.pem)"
```

4. Deploy:
```bash
git push azure main
```

## Step 5: Verify Installation

1. Create a test pull request in a repository where the app is installed
2. Check that the size label is applied
3. Review logs:
   - Local: Check console output
   - Heroku: `heroku logs --tail`
   - AWS Lambda: Check CloudWatch logs
   - Docker: `docker logs container-name`

## Customization

### Custom Labels

Create `.github/labels.yml` in your repositories:

```yaml
XS:
  name: size/XS
  lines: 0
  color: 3CBF00
S:
  name: size/S
  lines: 10
  color: 5D9801
M:
  name: size/M
  lines: 30
  color: 7F7203
L:
  name: size/L
  lines: 100
  color: A14C05
XL:
  name: size/XL
  lines: 500
  color: C32607
XXL:
  name: size/XXL
  lines: 1000
  color: E50009
```

### Exclude Files

Use `.gitattributes` to exclude files from size calculation:

```gitattributes
*.meta linguist-generated=true
package-lock.json linguist-generated=true
```

## Troubleshooting

### Webhooks not received

1. Check your webhook URL is correct in GitHub App settings
2. Ensure your app is publicly accessible
3. Check webhook delivery in GitHub App settings → Advanced → Recent Deliveries

### Authentication errors

1. Verify `APP_ID` is correct
2. Check that `PRIVATE_KEY` is properly formatted
3. Ensure the private key matches your GitHub App

### App not labeling PRs

1. Verify the app is installed on the repository
2. Check app has correct permissions (Pull requests: Read & write)
3. Review application logs for errors

## Security Considerations

1. **Never commit your `.env` file or `.pem` files** - they're in `.gitignore` by default
2. **Rotate secrets regularly** - especially webhook secrets and private keys
3. **Use environment-specific secrets** - different secrets for dev/staging/prod
4. **Enable HTTPS** - always use HTTPS for webhook URLs
5. **Monitor logs** - set up Sentry or similar for error tracking

## Updating Your Instance

To update your self-hosted instance:

```bash
git pull origin main
npm install
# Redeploy using your chosen method
```

## Getting Help

- **Issues**: https://github.com/noqcks/pull-request-size/issues
- **Probot Documentation**: https://probot.github.io/docs/
- **GitHub Apps Documentation**: https://docs.github.com/en/developers/apps

## License

[MIT](LICENSE)
