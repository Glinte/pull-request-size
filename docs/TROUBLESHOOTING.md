# Troubleshooting Guide

Common issues and solutions when self-hosting Pull Request Size.

## Table of Contents
- [GitHub App Setup Issues](#github-app-setup-issues)
- [Authentication & Authorization](#authentication--authorization)
- [Webhook Issues](#webhook-issues)
- [Deployment Issues](#deployment-issues)
- [Runtime Issues](#runtime-issues)
- [Performance Issues](#performance-issues)

## GitHub App Setup Issues

### Can't create GitHub App

**Problem:** Error creating GitHub App or can't access settings page.

**Solution:**
- For personal apps: Visit https://github.com/settings/apps
- For organization apps: Visit https://github.com/organizations/YOUR_ORG/settings/apps
- Ensure you have admin permissions for the organization
- Try a different browser or clear cache

### App permissions not working

**Problem:** App can't label PRs or access files.

**Solution:**
1. Check app permissions in settings:
   - Pull requests: **Read & write** (not just Read)
   - Metadata: **Read-only**
   - Single file: **Read-only** for `.gitattributes`
2. After changing permissions, reinstall the app on repositories
3. Check "Installed GitHub Apps" in repository settings

## Authentication & Authorization

### "Bad credentials" error

**Problem:** App logs show authentication errors.

**Solution:**
1. Verify `APP_ID` is correct (numeric value from GitHub App settings)
2. Check `PRIVATE_KEY` format:
   ```bash
   # Should start with -----BEGIN RSA PRIVATE KEY-----
   # and end with -----END RSA PRIVATE KEY-----
   
   # Use our helper script to format it correctly:
   ./scripts/format-private-key.sh your-key.pem
   ```
3. Ensure the private key matches your GitHub App
4. Generate a new private key if needed

### "Invalid signature" webhook error

**Problem:** GitHub shows "Invalid signature" in webhook deliveries.

**Solution:**
1. Verify `WEBHOOK_SECRET` matches exactly what's in GitHub App settings
2. Check for extra spaces or quotes in the secret
3. Regenerate webhook secret if needed:
   ```bash
   ruby -rsecurerandom -e 'puts SecureRandom.hex(20)'
   ```
4. Update both GitHub App settings and your `.env` file

### Private key format issues

**Problem:** "Invalid key" or "PEM routines" errors.

**Solution:**
```bash
# Option 1: Use inline format with \n
PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\nYOUR_KEY_HERE\n-----END RSA PRIVATE KEY-----"

# Option 2: Use base64 encoded format
PRIVATE_KEY=$(cat your-key.pem | base64)

# Option 3: Use file path (local development only)
PRIVATE_KEY_PATH=./your-key.pem
```

## Webhook Issues

### Webhooks not received

**Problem:** PRs opened but no labels applied, no logs showing webhook received.

**Solution:**
1. Check webhook URL in GitHub App settings
2. Ensure URL is publicly accessible (not localhost unless using smee)
3. Check "Recent Deliveries" in GitHub App → Advanced:
   - Green checkmark = successful
   - Red X = failed (click to see error)
4. Verify endpoint path is `/api/github/webhooks`
5. For local development, use smee.io:
   ```bash
   npm install -g smee-client
   smee --url https://smee.io/YOUR_ID --path /api/github/webhooks --port 3000
   ```

### Webhook timeout errors

**Problem:** GitHub shows "Timeout" in Recent Deliveries.

**Solution:**
1. Increase function timeout (AWS Lambda, Cloud Run, etc.)
2. Optimize performance (see Performance Issues)
3. Check app isn't sleeping (Heroku free tier)
4. Review logs for slow operations

### SSL/HTTPS errors

**Problem:** Webhook fails with SSL certificate errors.

**Solution:**
1. Ensure your hosting platform supports HTTPS
2. Use a reverse proxy (Nginx, Caddy) for SSL termination
3. For Heroku/AWS Lambda/Cloud Run: HTTPS is automatic
4. For Docker on VPS: Set up Caddy or Certbot

## Deployment Issues

### Docker build fails

**Problem:** `docker build` errors.

**Solution:**
```bash
# Clean build without cache
docker build --no-cache -t pull-request-size .

# Check Docker is running
docker ps

# Check for syntax errors in Dockerfile
cat Dockerfile

# If npm install fails, try:
# 1. Delete node_modules locally
# 2. Update package-lock.json
# 3. Rebuild
```

### Heroku deployment fails

**Problem:** `git push heroku main` fails or app crashes.

**Solution:**
```bash
# Check logs
heroku logs --tail -a your-app-name

# Verify buildpack (should auto-detect Node.js)
heroku buildpacks -a your-app-name

# Ensure Procfile exists
cat Procfile
# Should contain: web: npm start

# Check Node version compatibility
heroku config:set NODE_VERSION=18.x -a your-app-name

# Verify all env vars are set
heroku config -a your-app-name
```

### AWS Lambda deployment fails

**Problem:** `serverless deploy` fails.

**Solution:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify serverless.yml syntax
npx serverless print

# Check region is valid
# Update in serverless.yml if needed

# Common issues:
# 1. IAM permissions - ensure deploying user has Lambda/API Gateway/CloudFormation permissions
# 2. Invalid environment variables
# 3. Function timeout too low - increase in serverless.yml

# Deploy with verbose output
npx serverless deploy --verbose
```

### Function size too large (Lambda)

**Problem:** Deployment fails due to package size limit.

**Solution:**
```bash
# Lambda has 50MB limit (250MB unzipped)

# Check package size
du -sh .serverless/*.zip

# Reduce size:
# 1. Add exclusions to serverless.yml
package:
  patterns:
    - '!tests/**'
    - '!coverage/**'
    - '!.github/**'
    - '!*.pem'
    - '!.git/**'
    - '!node_modules/.cache/**'

# 2. Use Lambda layers for dependencies
# 3. Consider using Docker-based Lambda if needed
```

## Runtime Issues

### App starts but doesn't label PRs

**Problem:** App is running, webhooks received, but no labels applied.

**Solution:**
1. Check app is installed on the repository
2. Verify app has write permissions
3. Check logs for errors:
   ```bash
   # Heroku
   heroku logs --tail -a your-app-name
   
   # AWS Lambda
   npx serverless logs -f webhooks --tail
   
   # Docker
   docker logs -f container-name
   ```
4. Test with a simple PR (1-2 line change)
5. Check if labels exist (they'll be created if not)

### Labels not being removed

**Problem:** Old size labels stay when PR size changes.

**Solution:**
- This is expected behavior - old labels are only removed if the new label is different
- Check logs to see if label removal is attempted
- Verify app has write permissions

### Custom labels not working

**Problem:** `.github/labels.yml` not being used.

**Solution:**
1. Ensure file path is exactly: `.github/labels.yml`
2. Check YAML syntax:
   ```yaml
   XS:
     name: size/XS
     lines: 0
     color: 3CBF00
   ```
3. Verify app has single file read permission
4. Check logs for YAML parsing errors
5. Try with default labels first to verify basic functionality

### Comments not being added

**Problem:** Size comments not appearing on PRs.

**Solution:**
1. Ensure `comment` field is defined in `.github/labels.yml`:
   ```yaml
   XXL:
     name: size/XXL
     lines: 1000
     color: E50009
     comment: |
       This PR is too large!
   ```
2. Verify app has write permission for issues/PRs
3. Check logs for comment creation errors

## Performance Issues

### Slow label application

**Problem:** Takes a long time to label PRs.

**Solution:**
1. Check number of files in PR (limit is 1000)
2. Large PRs take longer to process
3. Increase function memory (AWS Lambda, Cloud Run)
4. Review logs for bottlenecks

### High costs (AWS/Cloud)

**Problem:** Unexpectedly high cloud costs.

**Solution:**
1. Check CloudWatch/Stackdriver logs for excessive invocations
2. Ensure webhook secret is correct (invalid requests shouldn't reach function)
3. Monitor function execution time
4. For AWS Lambda:
   ```bash
   # Check usage
   npx serverless metrics
   
   # View costs in AWS Cost Explorer
   ```
5. Consider AWS Lambda reserved capacity for consistent load
6. Set up billing alerts

### Cold start issues (Serverless)

**Problem:** First request after idle period is slow.

**Solution:**
1. Keep functions warm with scheduled pings:
   ```yaml
   # In serverless.yml
   functions:
     webhooks:
       events:
         - schedule: rate(5 minutes)
   ```
2. Increase memory allocation (faster startup)
3. Use provisioned concurrency (AWS Lambda)
4. Consider moving to always-on hosting (Heroku, VPS)

## Getting Additional Help

If these solutions don't help:

1. **Check logs thoroughly**: Most issues show errors in logs
2. **Enable debug logging**: Set `LOG_LEVEL=debug` in environment
3. **Test webhook manually**: Use curl or Postman to send test webhooks
4. **Simplify**: Test with minimal configuration first
5. **GitHub Issues**: https://github.com/noqcks/pull-request-size/issues
6. **Probot Docs**: https://probot.github.io/docs/
7. **Platform support**: Check your hosting platform's documentation

## Debug Mode

Enable detailed logging:

```bash
# In .env or environment variables
LOG_LEVEL=debug
NODE_ENV=development
```

Then check logs for detailed output.

## Useful Commands for Debugging

```bash
# Check environment variables are loaded
printenv | grep -E "APP_ID|WEBHOOK_SECRET|PRIVATE_KEY"

# Test GitHub API connectivity
curl -H "Authorization: Bearer YOUR_INSTALLATION_TOKEN" \
  https://api.github.com/rate_limit

# Test webhook endpoint
curl -X POST https://your-app/api/github/webhooks \
  -H "Content-Type: application/json" \
  -d '{"action":"test"}'

# Check app is responding
curl https://your-app/probot

# View container/process logs
# Docker:
docker logs -f container-name

# PM2:
pm2 logs

# systemd:
journalctl -u your-service -f
```
