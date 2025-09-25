# OpenTofu Role

This role manages OpenTofu/Terraform deployments from Ansible.

## Features

- Checks for OpenTofu installation
- Initializes OpenTofu configuration
- Runs plan or apply operations
- Captures and displays outputs
- Provides deployment summary

## Variables

- `terraform_directory`: Path to Terraform configuration (default: `../terraform` relative to playbook)
- `terraform_plan_only`: Only run plan, don't apply (default: false)
- `terraform_auto_approve`: Auto-approve apply (default: true)

## Usage

### Apply Terraform configuration
```yaml
- name: Deploy infrastructure with OpenTofu
  include_role:
    name: opentofu
```

### Plan only (no apply)
```yaml
- name: Plan Terraform changes
  include_role:
    name: opentofu
  vars:
    terraform_plan_only: true
```

### Custom directory
```yaml
- name: Deploy from custom directory
  include_role:
    name: opentofu
  vars:
    terraform_directory: /path/to/terraform/config
```

## Prerequisites

- OpenTofu installed on the Ansible control node
- Valid Terraform configuration in the specified directory
- Appropriate cloud/infrastructure credentials configured

## Tags

- `terraform`: Run all OpenTofu tasks
- `infrastructure`: Infrastructure deployment tasks