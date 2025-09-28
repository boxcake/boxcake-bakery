#!/bin/bash
# Test script to verify OpenTofu state persistence

set -e

echo "🧪 Testing OpenTofu State Persistence"
echo "======================================"

# Create test directories
TEST_DIR="/tmp/homelab-state-test"
TFSTATE_DIR="/tmp/test-tfstate"

echo "📁 Creating test directories..."
mkdir -p "$TEST_DIR"
mkdir -p "$TFSTATE_DIR"

cd "$TEST_DIR"

# Create a minimal Terraform configuration for testing
cat > main.tf << 'EOF'
terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "test" {
  content  = "Hello from persistent state test!"
  filename = "/tmp/test-file.txt"
}

output "test_file_content" {
  value = local_file.test.content
}
EOF

echo "🔧 Testing OpenTofu commands with custom state file..."

# Test init
echo "- Running tofu init..."
tofu init > /dev/null 2>&1

# Test plan with custom state
echo "- Running tofu plan with custom state..."
tofu plan -state="$TFSTATE_DIR/terraform.tfstate" -out=tfplan > /dev/null 2>&1

# Test apply with custom state
echo "- Running tofu apply with custom state..."
tofu apply -state="$TFSTATE_DIR/terraform.tfstate" tfplan > /dev/null 2>&1

# Verify state file exists in custom location
if [ -f "$TFSTATE_DIR/terraform.tfstate" ]; then
    echo "✅ State file created in custom location: $TFSTATE_DIR/terraform.tfstate"
else
    echo "❌ State file NOT found in custom location"
    exit 1
fi

# Test state list with custom state
echo "- Testing tofu state list with custom state..."
RESOURCES=$(tofu state list -state="$TFSTATE_DIR/terraform.tfstate")
if [[ "$RESOURCES" == *"local_file.test"* ]]; then
    echo "✅ State contains expected resources"
else
    echo "❌ State does not contain expected resources"
    exit 1
fi

# Test output with custom state
echo "- Testing tofu output with custom state..."
OUTPUT=$(tofu output -state="$TFSTATE_DIR/terraform.tfstate" -raw test_file_content)
if [[ "$OUTPUT" == "Hello from persistent state test!" ]]; then
    echo "✅ Output command works with custom state"
else
    echo "❌ Output command failed with custom state"
    exit 1
fi

# Cleanup test apply
echo "- Cleaning up test resources..."
tofu destroy -state="$TFSTATE_DIR/terraform.tfstate" -auto-approve > /dev/null 2>&1

# Cleanup test directories
rm -rf "$TEST_DIR"
rm -rf "$TFSTATE_DIR"
rm -f "/tmp/test-file.txt"

echo ""
echo "🎉 All tests passed! OpenTofu state persistence is working correctly."
echo "   State files can be stored in custom locations using the -state parameter."