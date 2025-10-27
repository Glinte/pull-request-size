# Deploying to Heroku

This guide shows how to deploy Pull Request Size to Heroku.

## Prerequisites

- [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli) installed
- A Heroku account
- Your GitHub App credentials (APP_ID, WEBHOOK_SECRET, PRIVATE_KEY)

## Step 1: Create a Heroku App

```bash
# Login to Heroku
heroku login

# Create a new app
heroku create your-pr-size-app

# Or if you want to specify a region
heroku create your-pr-size-app --region eu
```

## Step 2: Set Environment Variables

```bash
# Set your GitHub App ID
heroku config:set APP_ID=123456

# Set your webhook secret
heroku config:set WEBHOOK_SECRET=your_webhook_secret

# Set your private key (from your .pem file)
heroku config:set PRIVATE_KEY="$(cat your-private-key.pem)"

# Optional: Set Sentry DSN for error tracking
heroku config:set SENTRY_DSN=your_sentry_dsn

# Set Node environment
heroku config:set NODE_ENV=production
```

## Step 3: Deploy

### Option A: Using Git

```bash
# Add Heroku remote (if not already added)
heroku git:remote -a your-pr-size-app

# Deploy
git push heroku main

# Or if you're on a different branch
git push heroku your-branch:main
```

### Option B: Using GitHub Integration

1. Go to your app's dashboard: `https://dashboard.heroku.com/apps/your-pr-size-app`
2. Click the **Deploy** tab
3. In "Deployment method", select **GitHub**
4. Connect your GitHub repository
5. Enable automatic deploys (optional)
6. Click **Deploy Branch**

## Step 4: Update GitHub App Webhook URL

1. Go to your GitHub App settings
2. Update the **Webhook URL** to: `https://your-pr-size-app.herokuapp.com/api/github/webhooks`
3. Save changes

## Step 5: Verify Deployment

```bash
# Check app logs
heroku logs --tail -a your-pr-size-app

# Check app status
heroku ps -a your-pr-size-app

# Open the app in browser
heroku open -a your-pr-size-app
```

## Scaling

Heroku's free tier should be sufficient for small to medium usage. For larger deployments:

```bash
# Upgrade to a paid dyno
heroku ps:scale web=1:standard-1x -a your-pr-size-app

# Or for higher performance
heroku ps:scale web=1:standard-2x -a your-pr-size-app
```

## Monitoring

View logs in real-time:
```bash
heroku logs --tail -a your-pr-size-app
```

Add Heroku's logging addon:
```bash
heroku addons:create papertrail -a your-pr-size-app
```

## Troubleshooting

### App crashes on startup

Check logs:
```bash
heroku logs -a your-pr-size-app
```

Verify environment variables are set:
```bash
heroku config -a your-pr-size-app
```

### Webhooks not received

1. Verify the webhook URL in GitHub App settings
2. Check if the app is running: `heroku ps -a your-pr-size-app`
3. Test the webhook endpoint manually
4. Check Recent Deliveries in GitHub App settings

### Private key issues

If you get authentication errors, verify your private key is correct:

```bash
# Check the private key is set
heroku config:get PRIVATE_KEY -a your-pr-size-app

# If needed, reset it
heroku config:set PRIVATE_KEY="$(cat your-private-key.pem)" -a your-pr-size-app
```

## Updating

To deploy updates:

```bash
# Pull latest changes
git pull origin main

# Push to Heroku
git push heroku main
```

## Cost

- **Free tier**: Suitable for testing and small deployments
  - Apps sleep after 30 minutes of inactivity
  - 550-1000 free dyno hours per month
  
- **Hobby tier ($7/month)**: 
  - Never sleeps
  - Custom domains
  
- **Standard tier ($25-$50/month)**:
  - Better performance
  - Metrics
  - Horizontal scaling

## Resources

- [Heroku Node.js Documentation](https://devcenter.heroku.com/articles/getting-started-with-nodejs)
- [Heroku Config Vars](https://devcenter.heroku.com/articles/config-vars)
- [Heroku Logs](https://devcenter.heroku.com/articles/logging)
