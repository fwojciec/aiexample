# Infrastructure Context for Book Scanner

This document provides a concise overview of the Book Scanner infrastructure managed with OpenTofu (Terraform).

## Quick Reference

- **Tool**: OpenTofu 1.8+ (open-source Terraform fork)
- **Cloud Provider**: Google Cloud Platform
- **State Storage**: GCS bucket (remote backend)
- **Environments**: `main` (production), `preview`, and PR-specific previews

## Infrastructure Components

### Core Services

1. **Cloud SQL (PostgreSQL 15)**
   - Instance: `bookscanner-db`
   - Databases: `bookscanner` (production), `bookscanner_preview` (preview)
   - Automatic backups and maintenance windows

2. **Artifact Registry**
   - Repository: `bookscanner` for Docker images
   - Location: `us-central1`

3. **Secret Manager**
   - Database credentials and URLs
   - API keys (Google Books, Firebase OAuth)
   - Session secrets
   - All secrets have automatic replication

### IAM Configuration

- **Compute Engine Default SA**: SQL client, Secret accessor, Vertex AI user
- **GitHub Actions CI SA**: Cloud Run admin, Artifact Registry writer, necessary deployment permissions

## Working with Infrastructure

### Local Development

```bash
# Navigate to terraform directory
cd terraform/

# Initialize OpenTofu
tofu init -backend-config="bucket=$STATE_BUCKET"

# Plan changes
tofu plan

# Apply changes (production)
tofu apply
```

### Environment Management

- Each environment uses workspace isolation
- Resource naming: `bookscanner-<resource>` or `<resource>-<environment>`
- Critical resources have deletion protection

### CI/CD Integration

The `terraform-ci.yml` workflow automatically:
- Validates formatting (`tofu fmt`)
- Checks configuration (`tofu validate`)
- Runs comprehensive tests (`tofu test`)

### Testing

Infrastructure tests in `terraform/tests/` validate:
- Resource configuration and naming
- Security settings
- IAM permissions
- Import compatibility

Run tests locally:
```bash
cd terraform/
tofu test
```

## Key Files

- `terraform/main.tf` - Provider configuration
- `terraform/variables.tf` - Input variables
- `terraform/*.tf` - Resource definitions
- `terraform/tests/*.tftest.hcl` - Test specifications

## Important Notes

1. **State Management**: Never commit state files. Remote state is in GCS.
2. **Secrets**: All sensitive values are in Secret Manager, never in code.
3. **Deletion Protection**: Cloud SQL and secrets cannot be accidentally deleted.
4. **Testing**: Always run `tofu test` before applying changes.

For deployment workflows, see `ai_context/cicd-workflows.md`.