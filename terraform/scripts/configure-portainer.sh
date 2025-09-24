#!/bin/sh
set -e

# Install jq and other tools for JSON processing and network debugging
apk add --no-cache jq curl bind-tools

echo "🚀 Configuring Portainer..."

# Try to resolve the service name first
echo "🔍 Checking service name resolution..."
if nslookup portainer-service >/dev/null 2>&1; then
  echo "✅ DNS resolution working"
  PORTAINER_URL="http://portainer-service:80"
else
  echo "⚠️  DNS resolution failed, trying to get service IP..."

  # Try to get the service IP using nslookup on different forms
  if nslookup portainer-service.${namespace}.svc.cluster.local >/dev/null 2>&1; then
    echo "✅ FQDN resolution working"
    PORTAINER_URL="http://portainer-service.${namespace}.svc.cluster.local:80"
  else
    echo "❌ Service name resolution failed completely"
    echo "🔧 Checking network configuration..."
    cat /etc/resolv.conf
    echo "🔧 Available services in DNS:"
    nslookup kubernetes.default.svc.cluster.local || echo "Even kubernetes service not resolvable"
    exit 1
  fi
fi

echo "📡 Using Portainer URL: $PORTAINER_URL"

# Wait for Portainer to be ready
echo "⏳ Waiting for Portainer to be accessible..."
RETRY_COUNT=0
MAX_RETRIES=60

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if curl -s $PORTAINER_URL/api/status >/dev/null 2>&1; then
    echo "✅ Portainer is ready"
    break
  fi
  echo "   Waiting for Portainer API... ($((RETRY_COUNT + 1))/$MAX_RETRIES)"
  sleep 5
  RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "❌ Timeout waiting for Portainer"
  exit 1
fi

# Check if admin user already exists
STATUS=$(curl -s -o /dev/null -w "%%{http_code}" $PORTAINER_URL/api/users/admin/check || echo "000")

if [ "$STATUS" = "204" ]; then
  echo "ℹ️  Admin user already configured, checking registry..."
else
  echo "🔐 Setting up admin user..."

  # Initialize admin user
  INIT_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"Username":"admin","Password":"${portainer_admin_password}"}' \
    $PORTAINER_URL/api/users/admin/init)

  echo "✅ Admin user created"
fi

# Get JWT token for further API calls
echo "🔑 Authenticating..."
TOKEN=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"Username":"admin","Password":"${portainer_admin_password}"}' \
  $PORTAINER_URL/api/auth | jq -r '.jwt')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Failed to get authentication token"
  exit 1
fi

echo "✅ Authentication successful"

# Check if registry already exists
REGISTRIES=$(curl -s -H "Authorization: Bearer $TOKEN" \
  $PORTAINER_URL/api/registries)

LOCAL_REGISTRY_EXISTS=$(echo "$REGISTRIES" | jq -r '.[] | select(.URL == "registry-service:5000") | .Name')

if [ -n "$LOCAL_REGISTRY_EXISTS" ]; then
  echo "ℹ️  Local registry already configured: $LOCAL_REGISTRY_EXISTS"
else
  echo "🐳 Registering local container registry..."
  curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{
      "Name": "Local Registry",
      "Type": 1,
      "URL": "registry-service:5000",
      "Authentication": false,
      "Username": "",
      "Password": ""
    }' \
    $PORTAINER_URL/api/registries

  echo "✅ Local registry registered"
fi

# Configure Portainer settings for better UX
echo "⚙️  Configuring Portainer settings..."
curl -s -X PUT \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "AllowBindMountsForRegularUsers": true,
    "AllowPrivilegedModeForRegularUsers": true,
    "AllowStackManagementForRegularUsers": true,
    "DisplayDonationHeader": false,
    "DisplayExternalContributors": false,
    "EnableTelemetry": false,
    "UserSessionTimeout": "8h"
  }' \
  $PORTAINER_URL/api/settings

echo "✅ Portainer settings configured"

echo "🎉 Portainer configuration complete!"
echo "   👤 Admin user: admin"
echo "   🔐 Password: ${portainer_admin_password}"
echo "   🐳 Registry: registry-service:5000"