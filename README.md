# GCP VPC Egress Terraform Module

Complete, production-ready Terraform module for setting up VPC egress infrastructure on Google Cloud Platform.

## Features

- **VPC Network** - Customizable network with auto-create subnets disabled
- **Subnets** - Support for multiple subnets with configurable CIDR blocks
- **Flow Logs** - VPC flow logging enabled for network troubleshooting
- **Cloud Router** - Regional router for outbound NAT
- **Cloud NAT** - Highly available NAT for outbound internet access
- **Firewall Rules** - Secure ingress/egress rules (PostgreSQL, SSH, internal)
- **Logging** - CloudLogging integration for NAT activity
- **Outputs** - Complete network information for consumption

## Usage

### Basic Example

```hcl
module "vpc_egress" {
  source = "git::https://github.com/DarojaAI/gcp-vpc-egress-terraform.git//terraform"

  project_id     = "my-project-id"
  region         = "us-central1"
  vpc_name       = "my-vpc"
  subnet_cidr    = "10.0.0.0/24"
  environment    = "production"
}

# Access outputs
output "vpc_id" {
  value = module.vpc_egress.vpc_id
}

output "subnet_id" {
  value = module.vpc_egress.subnet_id
}

output "router_id" {
  value = module.vpc_egress.router_id
}
```

### With VM Integration

```hcl
module "vpc_egress" {
  source = "git::https://github.com/DarojaAI/gcp-vpc-egress-terraform.git//terraform"
  
  project_id = var.project_id
  region     = var.region
  vpc_name   = "rag-research-vpc"
  subnet_cidr = "10.1.0.0/24"
}

# PostgreSQL VM using the VPC
resource "google_compute_instance" "postgres" {
  name         = "postgres-vm"
  machine_type = "e2-medium"
  zone         = "${var.region}-b"

  network_interface {
    subnetwork = module.vpc_egress.subnet_id
    access_config {
      nat_ip = google_compute_address.postgres_external.address
    }
  }

  # VM can now reach internet via Cloud NAT for apt-get, etc.
}
```

## Variables

| Variable | Description | Type | Default |
|----------|-------------|------|---------|
| `project_id` | GCP Project ID | string | required |
| `region` | GCP region | string | required |
| `vpc_name` | VPC network name | string | required |
| `subnet_name` | Subnet name (appended to vpc_name) | string | "subnet" |
| `subnet_cidr` | Subnet CIDR block | string | "10.0.0.0/24" |
| `environment` | Environment (dev, staging, prod) | string | "dev" |
| `enable_flow_logs` | Enable VPC flow logging | bool | true |
| `allow_ssh` | Allow SSH from anywhere | bool | true |
| `allow_postgres` | Allow PostgreSQL ingress | bool | true |
| `postgres_port` | PostgreSQL port | number | 5432 |

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC network ID |
| `vpc_name` | VPC network name |
| `subnet_id` | Subnet ID |
| `subnet_name` | Subnet name |
| `router_id` | Cloud Router ID |
| `nat_ip` | NAT IP address (auto-allocated) |
| `firewall_postgres_rule` | PostgreSQL firewall rule name |
| `firewall_ssh_rule` | SSH firewall rule name |

## How It Works

### VPC Network
- Auto-create subnetworks disabled for full control
- Supports multiple subnets with independent configurations

### Cloud NAT
- **AUTO_ONLY** allocation: GCP manages IP addresses automatically
- **ALL_SUBNETWORKS_ALL_IP_RANGES**: Every VM in every subnet gets egress access
- **Logging**: All NAT operations logged for troubleshooting

### Firewall Rules
- **PostgreSQL (5432)**: From subnet CIDR only
- **SSH (22)**: From anywhere (0.0.0.0/0) for remote access
- **Internal**: All traffic between subnets allowed
- **Egress**: All outbound traffic allowed (443, 80, DNS, etc.)

### Flow Logs
- Captures traffic flow information
- 10-minute aggregation interval
- 50% sampling for cost efficiency

## Security

### Recommendations

1. **SSH Access** - Restrict with `allow_ssh_from_cidrs` instead of 0.0.0.0/0:
   ```hcl
   allow_ssh_from_cidrs = ["YOUR_IP/32"]
   ```

2. **PostgreSQL** - Only accessible from within the VPC
   - External access only via private IP
   - Use Cloud SQL Proxy if external access needed

3. **Network Isolation** - Create separate VPCs per environment
   - Use this module for each environment
   - Configure VPC peering for cross-environment access if needed

## Troubleshooting

### VMs Can't Access Internet
- Verify NAT is running: `gcloud compute routers list`
- Check firewall egress rules allow outbound traffic
- Verify VM has external IP or NAT access

### SSH Connection Fails
- Check firewall rule allows port 22 from your IP
- Verify VM has `target_tags = ["allow-ssh"]` or similar
- Test with: `gcloud compute ssh INSTANCE_NAME --zone=ZONE`

### apt-get Fails
- Confirm NAT is enabled (check this module outputs)
- Check VPC flow logs for DNS resolution issues
- Test DNS from VM: `nslookup google.com 8.8.8.8`

## Cost Optimization

### NAT Costs
- **Data processed**: ~$0.045/GB (processed through NAT)
- **Port allocation**: ~$0.025/hour per port (rarely needed, usually <10 ports)

### Reducing Costs
1. Use private Cloud Artifact Registry (avoid egress charges)
2. Cache package downloads (apt-cacher-ng, etc.)
3. Use Cloud NAT gateway machines instead for high-volume workloads

## Integration with Other Modules

This module can be easily integrated with:
- **gcp-postgres-terraform** - PostgreSQL VM deployment
- **gcp-dbt-terraform** - dbt Cloud Run jobs
- **gcp-kubernetes-terraform** - GKE clusters

Example:
```hcl
module "vpc" {
  source = "git::https://github.com/DarojaAI/gcp-vpc-egress-terraform.git//terraform"
  ...
}

module "postgres" {
  source = "git::https://github.com/DarojaAI/gcp-postgres-terraform.git//terraform"
  
  # Use VPC from egress module
  network_id  = module.vpc.vpc_id
  subnet_id   = module.vpc.subnet_id
  ...
}
```

## License

Apache 2.0

## Support

Issues & questions: https://github.com/DarojaAI/gcp-vpc-egress-terraform/issues
