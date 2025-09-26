#!/usr/bin/env python3
"""
Debug script to check if all expected paths exist for the backend
"""
from pathlib import Path
import sys

# Add the backend directory to Python path
backend_dir = Path(__file__).parent / "web-config" / "backend"
sys.path.insert(0, str(backend_dir))

print("🔍 Checking backend paths and dependencies...")
print(f"Backend directory: {backend_dir}")
print(f"Current working directory: {Path.cwd()}")

# Check repo structure
repo_root = Path(__file__).parent
print(f"\n📁 Repository root: {repo_root}")

expected_dirs = [
    repo_root / "ansible",
    repo_root / "terraform",
    repo_root / "configs",
    repo_root / "ansible" / "vars",
    repo_root / "web-config" / "backend",
]

for dir_path in expected_dirs:
    status = "✅" if dir_path.exists() else "❌"
    print(f"{status} {dir_path}")

# Test importing the modules
print(f"\n🐍 Testing Python imports...")
try:
    from config_generator import ConfigGenerator
    print("✅ ConfigGenerator import successful")

    # Test instantiation
    config_gen = ConfigGenerator()
    print("✅ ConfigGenerator instantiation successful")
    print(f"   - repo_root: {config_gen.repo_root}")
    print(f"   - ansible_dir: {config_gen.ansible_dir} (exists: {config_gen.ansible_dir.exists()})")
    print(f"   - terraform_dir: {config_gen.terraform_dir} (exists: {config_gen.terraform_dir.exists()})")
    print(f"   - configs_dir: {config_gen.configs_dir} (exists: {config_gen.configs_dir.exists()})")

except Exception as e:
    print(f"❌ ConfigGenerator import/instantiation failed: {e}")
    import traceback
    traceback.print_exc()

try:
    from deployment import DeploymentManager
    print("✅ DeploymentManager import successful")

    deploy_mgr = DeploymentManager()
    print("✅ DeploymentManager instantiation successful")
except Exception as e:
    print(f"❌ DeploymentManager import/instantiation failed: {e}")
    import traceback
    traceback.print_exc()

# Test the default config generation
print(f"\n⚙️  Testing default configuration...")
try:
    from main import HomeLabConfig, ServicesConfig, NetworkConfig, StorageConfig

    default_config = HomeLabConfig(
        admin_password="",
        services=ServicesConfig(),
        network=NetworkConfig(),
        storage=StorageConfig()
    )
    print("✅ Default configuration creation successful")
    print(f"   Config dict: {default_config.dict()}")

except Exception as e:
    print(f"❌ Default configuration creation failed: {e}")
    import traceback
    traceback.print_exc()