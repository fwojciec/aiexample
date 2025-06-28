# CI/CD Workflows and GitHub Actions

## Overview

The Book Scanner project uses GitHub Actions for continuous integration and deployment. The workflows support versioned deployments, preview environments for pull requests, and automatic resource cleanup.

## Workflow Files

All workflows are located in `.github/workflows/`:

### deploy.yml - Production Deployment
- **Triggers**: Push to `main` branch or manual workflow dispatch
- **Purpose**: Deploy application to production environment
- **Key Features**:
  - Manual version override via workflow dispatch
  - Docker image building and pushing to Artifact Registry
  - OpenTofu-based infrastructure updates
  - Post-deployment health checks

### preview.yml - Preview Environment Deployment
- **Triggers**: Pull request events (opened, synchronized, reopened) or manual dispatch
- **Purpose**: Create isolated preview environments for testing
- **Key Features**:
  - Automatic PR number detection
  - Versioned naming (e.g., `bookscanner-preview-pr-123`)
  - PR comment automation with preview URLs
  - Schema-per-version database isolation
  - Health check validation

### cleanup.yml - Resource Cleanup
- **Triggers**: Pull request closed/merged or manual dispatch
- **Purpose**: Remove preview environment resources
- **Operations**:
  - Destroy Cloud Run services
  - Delete container images from Artifact Registry
  - Clean up Terraform workspace resources

## Prerequisites

### 1. GitHub Secrets Configuration

Required secrets in repository settings:

```
GCP_SA_KEY          # Base64-encoded service account key
# Infrastructure managed via OpenTofu CLI
```

To get the service account key:
```bash
pulumi stack output github_actions_service_account_key_base64
```

### 2. Service Account Permissions

The GitHub Actions service account requires these GCP roles:
- `roles/run.admin` - Deploy and manage Cloud Run services
- `roles/cloudbuild.builds.editor` - Build container images
- `roles/artifactregistry.writer` - Push images to registry
- `roles/serviceusage.serviceUsageConsumer` - Use GCP services
- `roles/iam.serviceAccountUser` - Impersonate service accounts
- `roles/secretmanager.secretAccessor` - Read application secrets
- `roles/cloudsql.client` - Connect to Cloud SQL
- `roles/compute.viewer` - List compute resources (OpenTofu)
- `roles/browser` - Browse GCP resources (OpenTofu)

### 3. Infrastructure Requirements

Before first deployment:
1. Artifact Registry repository must exist
2. GitHub Actions service account must be configured
3. Terraform workspace must be initialized

## Environment Configuration

All workflows use consistent environment variables:

```yaml
env:
  GOOGLE_CLOUD_PROJECT: bookscanner-462507
  GOOGLE_CLOUD_REGION: us-central1
  PULUMI_ORG: fwojciec              # For preview/cleanup workflows
  PULUMI_PROJECT: bookscanner        # For preview/cleanup workflows
  PULUMI_STACK: fwojciec/bookscanner/main  # For main deployment only
```

## Stack Management Strategy

The project uses different Terraform workspaces for isolation:

- **Main Stack** (`fwojciec/bookscanner/main`): Contains all shared resources (database, secrets, IAM)
- **Preview Stacks** (`fwojciec/bookscanner/preview-pr-{number}`): Contains only Cloud Run service
  - References database from main stack
  - Completely isolated state
  - Easy cleanup by destroying entire stack

## Versioning Strategy

### Naming Conventions
- **Production**: `bookscanner-main`
- **Preview**: `bookscanner-preview-pr-{number}`
- **Feature branches**: `bookscanner-preview-{sanitized-branch-name}`

### Version Sanitization Rules
- Convert to lowercase
- Replace special characters with hyphens
- Maximum 52 characters
- Must start with letter (prepends 'v' if needed)
- Remove consecutive hyphens

### Database Schema Isolation
Each deployment gets an isolated PostgreSQL schema:
- **Production**: `public`
- **PR deployments**: `bookscanner_pr_{number}`
- **Feature branches**: `bookscanner_feat_{name}`

## Deployment Flow

### Pull Request Workflow
1. Developer opens PR
2. Preview workflow triggers automatically
3. Builds and pushes Docker image with PR-specific tag
4. Deploys to Cloud Run with versioned name
5. Creates isolated database schema
6. Posts preview URL as PR comment
7. Runs health checks

### Production Workflow
1. PR merged to main
2. Deploy workflow triggers
3. Builds and pushes Docker image
4. Updates production Cloud Run service
5. Validates deployment

### Cleanup Flow
1. PR closed or merged
2. Cleanup workflow triggers
3. Destroys Cloud Run service
4. Deletes container images
5. Removes Terraform resources

## Manual Operations

### Trigger Manual Deployment
1. Navigate to Actions tab in GitHub
2. Select appropriate workflow
3. Click "Run workflow"
4. Fill required parameters:
   - For preview: PR number
   - For deploy: Optional version override

### Check Deployment Status
```bash
# List recent workflow runs
gh run list --workflow=preview.yml

# View specific run details
gh run view <run-id>

# Watch run in progress
gh run watch <run-id>
```

## Troubleshooting

### Common Issues

**"repository doesn't exist" error**
- Artifact Registry repository not created
- Solution: Run `pulumi up` in infrastructure directory

**Authentication failures**
- Invalid or expired service account key
- Solution: Regenerate key and update GCP_SA_KEY secret

**Terraform permission errors**
- Missing IAM roles on service account
- Solution: Add required roles via infrastructure code

**Health check failures**
- Service not ready or misconfigured
- Check Cloud Run logs for startup errors

### Debugging Commands

```bash
# Check service status
gcloud run services describe bookscanner-preview-pr-123 \
  --region=us-central1

# View service logs
gcloud run services logs read bookscanner-preview-pr-123 \
  --region=us-central1 --limit=50

# List container images
gcloud container images list-tags \
  us-central1-docker.pkg.dev/bookscanner-462507/bookscanner/bookscanner
```

## Best Practices

1. **Always test locally first**
   - Run `make validate` before pushing
   - Test Docker build locally

2. **Monitor deployments**
   - Check GitHub Actions logs
   - Verify health checks pass
   - Review Cloud Run metrics

3. **Resource management**
   - Ensure cleanup runs for closed PRs
   - Periodically check for orphaned resources
   - Monitor costs for preview environments

4. **Security**
   - Rotate service account keys periodically
   - Use least-privilege IAM roles
   - Never commit secrets to repository

## Integration with Development Workflow

1. **Feature Development**
   ```bash
   git checkout -b feature/my-feature
   # Make changes
   git push -u origin feature/my-feature
   # Open PR - preview deploys automatically
   ```

2. **Testing Preview**
   - Wait for PR comment with URL
   - Test feature in isolated environment
   - Database changes don't affect production

3. **Deployment to Production**
   - Merge PR after approval
   - Automatic deployment to main
   - Preview resources cleaned up

## Future Improvements

Tracked in GitHub issues:
- #122: Improve Docker build performance with caching
- #123: Fix preview environment naming to use environment value

Potential enhancements:
- Blue-green deployments for zero-downtime updates
- Automatic rollback on failed health checks
- Integration with monitoring/alerting systems
- Cost tracking per preview environment