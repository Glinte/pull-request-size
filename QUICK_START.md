# Quick Start Guide for Self-Hosting

This is a condensed version of the self-hosting guide for users who want to get up and running quickly.

## TL;DR

```bash
# 1. Create a GitHub App and get credentials
# Visit: https://github.com/settings/apps/new

# 2. Clone and configure
git clone https://github.com/YOUR_USERNAME/pull-request-size.git
cd pull-request-size
cp .env.example .env

# 3. Edit .env with your GitHub App credentials
# APP_ID, WEBHOOK_SECRET, PRIVATE_KEY

# 4. Choose your deployment method and deploy
```

## Fastest Deployment Options

### 🐳 Docker (Recommended for Quick Testing)

```bash
# Build and run
docker build -t pr-size .
docker run -d -p 3000:3000 --env-file .env pr-size

# Or with docker-compose
docker-compose up -d
```

Your app will be running at `http://localhost:3000`

### ☁️ Heroku (Recommended for Production)

```bash
# Install Heroku CLI, then:
heroku create my-pr-size
heroku config:set APP_ID=your_id
heroku config:set WEBHOOK_SECRET=your_secret
heroku config:set PRIVATE_KEY="$(cat your-key.pem)"
git push heroku main
```

Your app will be at `https://my-pr-size.herokuapp.com`

### ⚡ AWS Lambda (Recommended for Scale)

```bash
# Configure AWS CLI, then:
npm install
npx serverless deploy
```

Get the endpoint from the output.

## Essential Environment Variables

Only 3 variables are required:

```bash
APP_ID=123456                           # From GitHub App settings
WEBHOOK_SECRET=your_random_secret       # Generate a random string
PRIVATE_KEY="-----BEGIN RSA...END-----" # From your downloaded .pem file
```

## Update GitHub App Webhook

After deployment, update your GitHub App's webhook URL to:

- **Heroku**: `https://your-app.herokuapp.com/api/github/webhooks`
- **AWS Lambda**: `https://xxx.execute-api.region.amazonaws.com/api/github/webhooks`
- **Docker (local)**: Use [smee.io](https://smee.io) for testing

## Verify It Works

1. Install your GitHub App on a repository
2. Create a test pull request
3. Check that a `size/*` label was added
4. Check your deployment logs for any errors

## Need More Details?

See the full [Self-Hosting Guide](SELF_HOSTING.md) for:
- Detailed GitHub App setup
- More deployment options (Vercel, Google Cloud, Azure)
- Troubleshooting
- Production best practices
- Security considerations

## Common Issues

**Webhook not received?**
- Verify webhook URL is correct in GitHub App settings
- Check "Recent Deliveries" in your GitHub App settings
- Ensure your app is publicly accessible

**Authentication errors?**
- Double-check APP_ID
- Verify PRIVATE_KEY format (should include header/footer)
- Ensure webhook secret matches

**Labels not applied?**
- Verify app has "Pull requests: Read & write" permission
- Check that app is installed on the repository
- Review application logs for errors

## Getting Help

- [Full Documentation](SELF_HOSTING.md)
- [Issues](https://github.com/noqcks/pull-request-size/issues)
- [Probot Docs](https://probot.github.io/docs/)
