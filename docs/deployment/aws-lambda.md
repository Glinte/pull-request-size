# Deploying to AWS Lambda with Serverless Framework

This guide shows how to deploy Pull Request Size to AWS Lambda using the Serverless Framework.

## Prerequisites

- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- [Serverless Framework](https://www.serverless.com/) installed
- An AWS account with appropriate permissions
- Your GitHub App credentials (APP_ID, WEBHOOK_SECRET, PRIVATE_KEY)

## Step 1: Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# You'll be prompted for:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., us-east-1)
# - Default output format (json)
```

## Step 2: Update serverless.yml

Edit `serverless.yml` in your project root:

```yaml
org: your-org-name        # Your serverless.com org (optional)
app: pr-size             # Your app name
service: pr-size         # Your service name

frameworkVersion: '3'
useDotenv: true

provider:
  name: aws
  runtime: nodejs18.x
  region: us-east-1      # Choose your preferred region
  environment:
    APP_ID: ${env:APP_ID}
    PRIVATE_KEY: ${env:PRIVATE_KEY}
    WEBHOOK_SECRET: ${env:WEBHOOK_SECRET}
    NODE_ENV: production
    LOG_LEVEL: info
    # Optional: Add SENTRY_DSN if you want error tracking
    # SENTRY_DSN: ${env:SENTRY_DSN}

functions:
  webhooks:
    name: pr-size-webhooks
    handler: src/handler.webhooks
    timeout: 25
    memorySize: 256
    events:
      - httpApi:
          path: /api/github/webhooks
          method: post

package:
  patterns:
    - '!tests/**'
    - '!coverage/**'
    - '!.github/**'
    - '!*.pem'
    - '!.env*'
```

## Step 3: Set Environment Variables

Create a `.env` file:

```bash
APP_ID=123456
WEBHOOK_SECRET=your_webhook_secret
PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\nYOUR_KEY_HERE\n-----END RSA PRIVATE KEY-----"
```

**Important**: Format the private key as a single line with `\n` for newlines.

To convert your .pem file:
```bash
cat your-private-key.pem | awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}'
```

## Step 4: Deploy

```bash
# Install dependencies
npm install

# Deploy to AWS
npx serverless deploy

# Or with a specific stage
npx serverless deploy --stage production
```

After deployment, you'll see output like:

```
endpoints:
  POST - https://abc123.execute-api.us-east-1.amazonaws.com/api/github/webhooks
functions:
  webhooks: pr-size-webhooks
```

## Step 5: Update GitHub App Webhook URL

1. Go to your GitHub App settings
2. Update the **Webhook URL** to the endpoint from the deployment output
3. Example: `https://abc123.execute-api.us-east-1.amazonaws.com/api/github/webhooks`
4. Save changes

## Step 6: Verify Deployment

```bash
# View logs
npx serverless logs -f webhooks --tail

# Get deployment info
npx serverless info

# Test the endpoint
curl -X POST https://your-api-endpoint/api/github/webhooks
```

## Using AWS Secrets Manager (Recommended for Production)

Instead of using environment variables, you can use AWS Secrets Manager:

### 1. Store secrets in AWS Secrets Manager

```bash
# Store the private key
aws secretsmanager create-secret \
  --name pr-size/private-key \
  --secret-string "$(cat your-private-key.pem)"

# Store the webhook secret
aws secretsmanager create-secret \
  --name pr-size/webhook-secret \
  --secret-string "your_webhook_secret"
```

### 2. Update serverless.yml

```yaml
provider:
  name: aws
  runtime: nodejs18.x
  region: us-east-1
  iam:
    role:
      statements:
        - Effect: Allow
          Action:
            - secretsmanager:GetSecretValue
          Resource:
            - arn:aws:secretsmanager:us-east-1:*:secret:pr-size/*
  environment:
    APP_ID: ${env:APP_ID}
    PRIVATE_KEY_SECRET_NAME: pr-size/private-key
    WEBHOOK_SECRET_NAME: pr-size/webhook-secret
    NODE_ENV: production
```

### 3. Update your code to fetch secrets

You'll need to modify `src/index.js` to fetch secrets from AWS Secrets Manager if the environment variables contain secret names.

## Monitoring with CloudWatch

View logs in CloudWatch:

```bash
# Tail logs
npx serverless logs -f webhooks --tail

# View specific time range
npx serverless logs -f webhooks --startTime 1h
```

Or in AWS Console:
1. Go to CloudWatch → Log groups
2. Find `/aws/lambda/pr-size-webhooks`
3. View log streams

## Custom Domain (Optional)

### Using AWS Certificate Manager + API Gateway

1. Request a certificate in ACM:
```bash
aws acm request-certificate \
  --domain-name api.yourdomain.com \
  --validation-method DNS
```

2. Add to `serverless.yml`:
```yaml
provider:
  httpApi:
    domain: api.yourdomain.com
```

3. Redeploy:
```bash
npx serverless deploy
```

## Cost Optimization

AWS Lambda pricing:
- First 1M requests/month: FREE
- First 400,000 GB-seconds of compute/month: FREE
- After free tier: $0.20 per 1M requests

For typical usage (small to medium projects), you'll likely stay in the free tier.

## Troubleshooting

### Deployment fails

Check your AWS credentials:
```bash
aws sts get-caller-identity
```

Verify Serverless Framework is installed:
```bash
serverless --version
```

### Function timeout

If webhooks are timing out, increase timeout in `serverless.yml`:
```yaml
functions:
  webhooks:
    timeout: 30  # Increase from 25 to 30 seconds
```

### Memory issues

Increase memory allocation:
```yaml
functions:
  webhooks:
    memorySize: 512  # Increase from 256 to 512 MB
```

### Private key authentication errors

Verify the key is properly formatted:
```bash
# Check environment variable
npx serverless invoke -f webhooks --log
```

## Updating

To deploy updates:

```bash
# Pull latest changes
git pull origin main

# Install any new dependencies
npm install

# Deploy
npx serverless deploy
```

## Removing the Deployment

To completely remove the deployment:

```bash
npx serverless remove
```

## Resources

- [Serverless Framework Documentation](https://www.serverless.com/framework/docs)
- [AWS Lambda Pricing](https://aws.amazon.com/lambda/pricing/)
- [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/)
- [CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/)
