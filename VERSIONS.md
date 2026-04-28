# Version Tracking: gcp-vpc-egress-terraform

## Current Version: 1.0.0

### Module Details
- **Name:** gcp-vpc-egress-terraform
- **Type:** VPC Egress Infrastructure Module
- **Status:** Production Ready
- **Repository:** https://github.com/DarojaAI/gcp-vpc-egress-terraform

### Dependencies
| Dependency | Version | Required | Status |
|------------|---------|----------|--------|
| Terraform | >= 1.6 | Yes | ✅ Compatible |
| Google Provider | ~> 7.0 | Yes | ✅ Current |
| gcp-postgres-terraform | >= 1.0.0 | Optional | ℹ️ For integration |

### Terraform Requirements
```hcl
terraform {
  required_version = ">= 1.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}
```

### Release History
| Version | Date | Changes | Status |
|---------|------|---------|--------|
| 1.0.0 | 2026-04-28 | Initial release - VPC, Router, NAT, Firewall | ✅ Released |

### Integration Guide

**Used By:**
- rag-research-tool (via module reference)
- Can be consumed by other GCP projects

**Breaking Changes:** None

**Upgrade Path:** Direct to latest

### Notes
- Module is reusable across projects
- Provider configuration handled by consumer
- Version file synced with GitHub releases
