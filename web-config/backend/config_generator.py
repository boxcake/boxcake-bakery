#!/usr/bin/env python3
"""
Configuration generator for Ansible and Terraform files
"""
import os
import yaml
import json
from pathlib import Path
from typing import Dict, Any, List
from jinja2 import Template
import ipaddress

class ConfigGenerator:
    def __init__(self):
        # When running from /opt/homelab, use that as the repo root
        self.repo_root = Path("/opt/homelab")
        self.ansible_dir = self.repo_root / "ansible"
        self.terraform_dir = self.repo_root / "terraform"
        self.configs_dir = self.repo_root / "configs"

    def validate_config(self, config: Dict[str, Any]) -> List[str]:
        """Validate configuration and return list of errors"""
        errors = []

        # Validate password
        if len(config.get('admin_password', '')) < 8:
            errors.append("Admin password must be at least 8 characters")

        # Validate network CIDRs
        network = config.get('network', {})
        try:
            pod_cidr = ipaddress.ip_network(network.get('pod_cidr', ''))
            service_cidr = ipaddress.ip_network(network.get('service_cidr', ''))
            homelab_pool = ipaddress.ip_network(network.get('homelab_pool', ''))
            user_pool = ipaddress.ip_network(network.get('user_pool', ''))

            # Check for overlaps
            if pod_cidr.overlaps(service_cidr):
                errors.append("Pod CIDR and Service CIDR cannot overlap")

            if not service_cidr.supernet_of(homelab_pool):
                errors.append("Homelab pool must be within Service CIDR")

            if not service_cidr.supernet_of(user_pool):
                errors.append("User pool must be within Service CIDR")

            if homelab_pool.overlaps(user_pool):
                errors.append("Homelab pool and User pool cannot overlap")

        except ValueError as e:
            errors.append(f"Invalid network configuration: {str(e)}")

        # Validate storage sizes
        storage = config.get('storage', {})
        for key, value in storage.items():
            if not self._validate_storage_size(value):
                errors.append(f"Invalid storage size for {key}: {value}")

        return errors

    def _validate_storage_size(self, size: str) -> bool:
        """Validate Kubernetes storage size format"""
        import re
        pattern = r'^\d+(\.\d+)?(Ei|Pi|Ti|Gi|Mi|Ki|E|P|T|G|M|K)$'
        return bool(re.match(pattern, size))

    async def generate_files(self, config: Dict[str, Any]) -> List[str]:
        """Generate configuration files from user input"""
        generated_files = []

        try:
            # Ensure directories exist
            self.configs_dir.mkdir(parents=True, exist_ok=True)
            (self.ansible_dir / "vars").mkdir(parents=True, exist_ok=True)

            # Generate user config file
            user_config_path = self.configs_dir / "user-config.yaml"
            with open(user_config_path, 'w') as f:
                yaml.dump({
                    'deployment': {
                        'admin_password': config['admin_password'],
                        'services': config['services']
                    },
                    'network': config['network'],
                    'storage': config['storage']
                }, f, default_flow_style=False)
            generated_files.append(str(user_config_path))

            # Generate network configuration
            await self._generate_network_config(config['network'])
            generated_files.append(str(self.configs_dir / "network-defaults.yaml"))

            # Generate Ansible variables override
            await self._generate_ansible_vars(config)
            generated_files.append(str(self.ansible_dir / "vars" / "user-overrides.yml"))

            # Generate Terraform variables
            await self._generate_terraform_vars(config)
            generated_files.append(str(self.terraform_dir / "user.tfvars"))

            return generated_files

        except Exception as e:
            raise Exception(f"Failed to generate configuration files: {str(e)}")

    async def _generate_network_config(self, network_config: Dict[str, Any]):
        """Generate network configuration file"""
        network_config_template = {
            'homelab': {
                'network': {
                    'pod_cidr': network_config['pod_cidr'],
                    'service_cidr': network_config['service_cidr'],
                    'pools': {
                        'homelab': {
                            'cidr': network_config['homelab_pool'],
                            'description': 'Core infrastructure (dashboard, portainer, registry, etc.)',
                            'auto_assign': True
                        },
                        'user': {
                            'cidr': network_config['user_pool'],
                            'description': 'User applications (gitea, databases, custom apps)',
                            'auto_assign': False
                        }
                    }
                }
            }
        }

        with open(self.configs_dir / "network-defaults.yaml", 'w') as f:
            yaml.dump(network_config_template, f, default_flow_style=False)

    async def _generate_ansible_vars(self, config: Dict[str, Any]):
        """Generate Ansible variables override file"""
        ansible_vars = {
            'portainer_admin_password': config['admin_password'],
            'portainer_storage_size': config['storage']['portainer_size'],
            'registry_storage_size': config['storage']['registry_size']
        }

        # Add service-specific variables based on selection
        services = config['services']
        if not services.get('portainer', True):
            ansible_vars['skip_portainer'] = True
        if not services.get('registry', True):
            ansible_vars['skip_registry'] = True
        if not services.get('registry_ui', True):
            ansible_vars['skip_registry_ui'] = True
        if not services.get('kubelish', True):
            ansible_vars['skip_kubelish'] = True

        with open(self.ansible_dir / "vars" / "user-overrides.yml", 'w') as f:
            f.write("---\n")
            f.write("# User configuration overrides\n")
            f.write("# Generated by web configuration interface\n\n")
            yaml.dump(ansible_vars, f, default_flow_style=False)

    async def _generate_terraform_vars(self, config: Dict[str, Any]):
        """Generate Terraform variables file"""
        terraform_vars = {
            'portainer_admin_password': config['admin_password'],
            'portainer_storage_size': config['storage']['portainer_size'],
            'registry_storage_size': config['storage']['registry_size'],
            'metallb_pool_name': 'homelab-services'
        }

        # Generate tfvars file
        tfvars_content = []
        for key, value in terraform_vars.items():
            if isinstance(value, str):
                tfvars_content.append(f'{key} = "{value}"')
            elif isinstance(value, bool):
                tfvars_content.append(f'{key} = {str(value).lower()}')
            else:
                tfvars_content.append(f'{key} = {value}')

        with open(self.terraform_dir / "user.tfvars", 'w') as f:
            f.write("# User configuration variables\n")
            f.write("# Generated by web configuration interface\n\n")
            f.write("\n".join(tfvars_content))
            f.write("\n")