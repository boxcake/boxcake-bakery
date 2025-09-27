#!/usr/bin/env python3
"""
Deployment manager for handling Ansible/Terraform execution
"""
import os
import asyncio
import subprocess
import uuid
import json
from pathlib import Path
from typing import Dict, Any, Optional
from datetime import datetime

class DeploymentManager:
    def __init__(self):
        # When running from /opt/homelab, use that as the repo root
        self.repo_root = Path("/opt/homelab")
        self.ansible_dir = f"{self.repo_root}/ansible"
        self.terraform_dir = f"{self.repo_root}/terraform"
        self.deployments = {}  # In-memory storage, could be replaced with database

    async def start_deployment(self, config: Dict[str, Any]) -> str:
        """Start a new deployment process"""
        deployment_id = str(uuid.uuid4())

        deployment_info = {
            'id': deployment_id,
            'status': 'starting',
            'config': config,
            'started_at': datetime.now().isoformat(),
            'steps': [],
            'current_step': None,
            'logs': []
        }

        self.deployments[deployment_id] = deployment_info

        # Start deployment in background
        asyncio.create_task(self._run_deployment(deployment_id))

        return deployment_id

    async def get_status(self, deployment_id: str) -> Dict[str, Any]:
        """Get current deployment status"""
        if deployment_id not in self.deployments:
            raise Exception(f"Deployment {deployment_id} not found")

        deployment = self.deployments[deployment_id]
        return {
            'id': deployment_id,
            'status': deployment['status'],
            'current_step': deployment['current_step'],
            'steps_completed': len([s for s in deployment['steps'] if s['status'] == 'completed']),
            'total_steps': len(deployment['steps']) if deployment['steps'] else 0,
            'started_at': deployment['started_at'],
            'finished_at': deployment.get('finished_at'),
            'logs': deployment['logs'][-50:],  # Return last 50 log lines
            'error': deployment.get('error')
        }

    async def _run_deployment(self, deployment_id: str):
        """Run the actual deployment process (Stage 2)"""
        deployment = self.deployments[deployment_id]

        try:
            await self._update_status(deployment_id, 'running')

            # Define Stage 2 deployment steps
            steps = [
                {'name': 'Prepare Stage 2 environment', 'function': self._prepare_stage2},
                {'name': 'Run Stage 2 Ansible playbook', 'function': self._run_stage2_ansible},
                {'name': 'Verify deployment', 'function': self._verify_deployment}
            ]

            deployment['steps'] = [{'name': step['name'], 'status': 'pending'} for step in steps]

            # Execute each step
            for i, step in enumerate(steps):
                step_name = step['name']
                await self._update_current_step(deployment_id, step_name)
                await self._update_step_status(deployment_id, i, 'running')

                try:
                    await step['function'](deployment_id)
                    await self._update_step_status(deployment_id, i, 'completed')
                    await self._add_log(deployment_id, f"✅ {step_name} completed successfully")
                except Exception as e:
                    await self._update_step_status(deployment_id, i, 'failed')
                    await self._add_log(deployment_id, f"❌ {step_name} failed: {str(e)}")
                    raise e

            await self._update_status(deployment_id, 'completed')
            deployment['finished_at'] = datetime.now().isoformat()

        except Exception as e:
            await self._update_status(deployment_id, 'failed')
            deployment['error'] = str(e)
            deployment['finished_at'] = datetime.now().isoformat()
            await self._add_log(deployment_id, f"❌ Deployment failed: {str(e)}")

    async def _prepare_stage2(self, deployment_id: str):
        """Prepare Stage 2 environment"""
        await self._add_log(deployment_id, "Preparing Stage 2 deployment environment...")

        # Check if we're running as the homelab user
        current_user = os.getenv('USER', 'unknown')
        await self._add_log(deployment_id, f"Running as user: {current_user}")

        # Verify we can find ansible-playbook
        # TODO - Why isnt this find function working?
                # ansible_playbook_cmd = await self._find_command(['ansible-playbook'], deployment_id)

        ansible_playbook_cmd = "/opt/homelab/venv/bin/ansible-playbook"

        if not ansible_playbook_cmd:
            raise Exception("ansible-playbook not found. Stage 1 bootstrap may not have completed properly.")

        await self._add_log(deployment_id, f"✅ Found ansible-playbook at: {ansible_playbook_cmd}")

    async def _find_command(self, commands: list, deployment_id: str) -> str:
        """Find a command in the system"""
        search_paths = [
            "/opt/homelab/venv/bin/"
            "/usr/local/bin/",
            "/usr/bin/",
            "/home/homelab/.local/bin/",
            ""  # PATH
        ]

        for cmd in commands:
            for path in search_paths:
                full_cmd = path + cmd if path else cmd
                try:
                    result = subprocess.run([full_cmd, "--version" if cmd != "tofu" else "version"],
                                          capture_output=True, timeout=10)
                    if result.returncode == 0:
                        return full_cmd
                except (subprocess.TimeoutExpired, FileNotFoundError):
                    continue
        return None

    async def _install_ansible_collections(self, deployment_id: str):
        """Install required Ansible collections"""
        await self._add_log(deployment_id, "Installing Ansible collections...")

        # Try to find ansible-galaxy in common locations
        ansible_galaxy_paths = [
            "/usr/local/bin/ansible-galaxy",
            "/usr/bin/ansible-galaxy",
            "/home/homelab/.local/bin/ansible-galaxy",
            "ansible-galaxy"  # fallback to PATH
        ]

        ansible_galaxy_cmd = None
        for path in ansible_galaxy_paths:
            try:
                result = subprocess.run([path, "--version"],
                                      capture_output=True,
                                      timeout=10)
                if result.returncode == 0:
                    ansible_galaxy_cmd = path
                    await self._add_log(deployment_id, f"Found ansible-galaxy at: {path}")
                    break
            except (subprocess.TimeoutExpired, FileNotFoundError):
                continue

        if not ansible_galaxy_cmd:
            await self._add_log(deployment_id, "ansible-galaxy not found, installing Ansible...")
            # Install Ansible first
            install_cmd = ["python3", "-m", "pip", "install", "--break-system-packages", "ansible"]
            result = await self._run_command(install_cmd, deployment_id)
            if result.returncode != 0:
                raise Exception("Failed to install Ansible")

            ansible_galaxy_cmd = "ansible-galaxy"

        requirements_file = self.ansible_dir / "requirements.yml"
        if requirements_file.exists():
            cmd = [
                ansible_galaxy_cmd, "collection", "install",
                "-r", str(requirements_file), "--force"
            ]
        else:
            cmd = [
                ansible_galaxy_cmd, "collection", "install",
                "kubernetes.core", "community.general", "--force"
            ]

        result = await self._run_command(cmd, deployment_id)
        if result.returncode != 0:
            raise Exception("Failed to install Ansible collections")

    async def _run_stage2_ansible(self, deployment_id: str):
        """Run Stage 2 Ansible playbook (full deployment)"""
        await self._add_log(deployment_id, "Starting Stage 2 full deployment...")

        # Find ansible-playbook command
        # ansible_playbook_cmd = await self._find_command(['ansible-playbook'], deployment_id)
        ansible_playbook_cmd = "/opt/homelab/venv/bin/ansible-playbook"

        if not ansible_playbook_cmd:
            raise Exception("ansible-playbook command not found")

        # Change to ansible directory
        original_cwd = os.getcwd()
        await self._add_log(deployment_id, f"Original CWD: {' '.join(original_cwd)}")
        await self._add_log(deployment_id, f"Ansible dir:  {' '.join(self.ansible_dir)}")

        os.chdir(self.ansible_dir)

        try:
            # Run the Stage 2 deployment playbook - we're already running as homelab user with sudo permissions
            cmd = [
                "sudo", ansible_playbook_cmd,
                "-i", "inventory/hosts.yml",
                "stage2-deploy.yml"
            ]
            await self._add_log(deployment_id, f"Running: {' '.join(cmd)}")
            await self._add_log(deployment_id, f"Working directory: {self.ansible_dir}")
            result = await self._run_command(cmd, deployment_id, stream_logs=True)
            if result.returncode != 0:
                raise Exception("Stage 2 Ansible playbook execution failed")

        finally:
            os.chdir(original_cwd)

    async def _run_ansible_playbook(self, deployment_id: str):
        """Run the main Ansible playbook"""
        await self._add_log(deployment_id, "Starting Ansible playbook execution...")

        # Try to find ansible-playbook in common locations
        ansible_playbook_paths = [
            "/usr/local/bin/ansible-playbook",
            "/usr/bin/ansible-playbook",
            "/home/homelab/.local/bin/ansible-playbook",
            "ansible-playbook"  # fallback to PATH
        ]

        # ansible_playbook_cmd = None
        ansible_playbook_cmd = "/opt/homelab/venv/bin/ansible-playbook"

        # for path in ansible_playbook_paths:
        #     try:
        #         result = subprocess.run([path, "--version"],
        #                               capture_output=True,
        #                               timeout=10)
        #         if result.returncode == 0:
        #             ansible_playbook_cmd = path
        #             await self._add_log(deployment_id, f"Found ansible-playbook at: {path}")
        #             break
        #     except (subprocess.TimeoutExpired, FileNotFoundError):
        #         continue

        if not ansible_playbook_cmd:
            raise Exception("ansible-playbook command not found")

        # Change to ansible directory
        original_cwd = os.getcwd()
        os.chdir(self.ansible_dir)

        try:
            cmd = [
                ansible_playbook_cmd,
                "-i", "inventory/hosts.yml",
                "site.yml"
            ]

            result = await self._run_command(cmd, deployment_id, stream_logs=True)
            if result.returncode != 0:
                raise Exception("Ansible playbook execution failed")

        finally:
            os.chdir(original_cwd)

    async def _run_terraform(self, deployment_id: str):
        """Run OpenTofu/Terraform deployment"""
        await self._add_log(deployment_id, "Applying OpenTofu configuration...")

        # Try to find tofu/terraform in common locations
        tofu_paths = [
            "/usr/local/bin/tofu",
            "/usr/bin/tofu",
            "/usr/local/bin/terraform",
            "/usr/bin/terraform",
            "tofu",  # fallback to PATH
            "terraform"  # fallback to PATH
        ]

        tofu_cmd = None
        for path in tofu_paths:
            try:
                result = subprocess.run([path, "version"],
                                      capture_output=True,
                                      timeout=10)
                if result.returncode == 0:
                    tofu_cmd = path
                    await self._add_log(deployment_id, f"Found Terraform/OpenTofu at: {path}")
                    break
            except (subprocess.TimeoutExpired, FileNotFoundError):
                continue

        if not tofu_cmd:
            raise Exception("OpenTofu/Terraform command not found")

        # Change to terraform directory
        original_cwd = os.getcwd()
        os.chdir(self.terraform_dir)

        try:
            # Initialize if needed
            init_cmd = [tofu_cmd, "init"]
            result = await self._run_command(init_cmd, deployment_id)
            if result.returncode != 0:
                raise Exception("OpenTofu init failed")

            # Apply configuration
            user_tfvars = Path("user.tfvars")
            if user_tfvars.exists():
                apply_cmd = [tofu_cmd, "apply", "-auto-approve", "-var-file=user.tfvars"]
            else:
                apply_cmd = [tofu_cmd, "apply", "-auto-approve"]

            result = await self._run_command(apply_cmd, deployment_id, stream_logs=True)
            if result.returncode != 0:
                raise Exception("OpenTofu apply failed")

        finally:
            os.chdir(original_cwd)

    async def _verify_deployment(self, deployment_id: str):
        """Verify that the deployment is working correctly"""
        await self._add_log(deployment_id, "Verifying deployment...")

        # Check if kubectl is available and cluster is responsive
        cmd = ["kubectl", "get", "nodes"]
        result = await self._run_command(cmd, deployment_id)
        if result.returncode != 0:
            raise Exception("Kubernetes cluster not accessible")

        # Check if pods are running
        cmd = ["kubectl", "get", "pods", "-A"]
        result = await self._run_command(cmd, deployment_id)
        if result.returncode != 0:
            raise Exception("Failed to get pod status")

        await self._add_log(deployment_id, "✅ Deployment verification completed")

    async def _run_command(self, cmd, deployment_id: str, stream_logs: bool = False) -> subprocess.CompletedProcess:
        """Run a command and capture output"""
        await self._add_log(deployment_id, f"Running: {' '.join(cmd)}")

        if stream_logs:
            # Stream output in real-time
            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.STDOUT
            )

            # Read lines and decode from bytes to string
            while True:
                line_bytes = await process.stdout.readline()
                if not line_bytes:
                    break
                line = line_bytes.decode('utf-8').rstrip()
                if line:  # Only log non-empty lines
                    await self._add_log(deployment_id, line)

            await process.wait()
            return_code = process.returncode

            # Create a mock result object
            class MockResult:
                def __init__(self, returncode):
                    self.returncode = returncode

            return MockResult(return_code)

        else:
            # Run command and capture all output
            result = subprocess.run(
                cmd,
                capture_output=True,
                timeout=300  # 5 minute timeout
            )

            if result.stdout:
                stdout = result.stdout.decode('utf-8')
                await self._add_log(deployment_id, stdout)
            if result.stderr:
                stderr = result.stderr.decode('utf-8')
                await self._add_log(deployment_id, f"STDERR: {stderr}")

            return result

    async def _update_status(self, deployment_id: str, status: str):
        """Update deployment status"""
        if deployment_id in self.deployments:
            self.deployments[deployment_id]['status'] = status

    async def _update_current_step(self, deployment_id: str, step_name: str):
        """Update current step"""
        if deployment_id in self.deployments:
            self.deployments[deployment_id]['current_step'] = step_name

    async def _update_step_status(self, deployment_id: str, step_index: int, status: str):
        """Update status of a specific step"""
        if deployment_id in self.deployments and step_index < len(self.deployments[deployment_id]['steps']):
            self.deployments[deployment_id]['steps'][step_index]['status'] = status

    async def _add_log(self, deployment_id: str, message: str):
        """Add a log message"""
        if deployment_id in self.deployments:
            timestamp = datetime.now().strftime("%H:%M:%S")
            log_entry = f"[{timestamp}] {message}"
            self.deployments[deployment_id]['logs'].append(log_entry)

            # Keep only last 1000 log entries to prevent memory issues
            if len(self.deployments[deployment_id]['logs']) > 1000:
                self.deployments[deployment_id]['logs'] = self.deployments[deployment_id]['logs'][-1000:]