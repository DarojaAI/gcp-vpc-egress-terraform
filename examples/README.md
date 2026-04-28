# Examples

This directory contains example configurations for the VPC Egress module.

## Usage

Each example is a standalone configuration. Choose one to use as a template for your infrastructure.

### Basic Example (`basic.tf`)

A minimal VPC setup with Cloud NAT for outbound internet access.

```bash
cd examples
terraform init
terraform plan -var-file=basic.tfvars
terraform apply -var-file=basic.tfvars
```

### With PostgreSQL (`with-postgres.tf`)

A VPC setup with PostgreSQL-specific firewall rules and network configuration.

To use this example, rename `with-postgres.tf` to `main.tf` and `basic.tf` to `basic.tf.bak`:

```bash
cd examples
mv basic.tf basic.tf.bak
mv with-postgres.tf main.tf
terraform init
terraform plan
terraform apply
```

Alternatively, copy the configuration to a new directory and use it there.
