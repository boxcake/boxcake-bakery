#!/bin/bash

# Quick restart script for the web service
echo "🔄 Restarting web configuration service..."
systemctl restart homelab-web-config

# Wait a moment and check status
sleep 2
if systemctl is-active --quiet homelab-web-config; then
    echo "✅ Service restarted successfully"

    # Test the API endpoint
    echo "🧪 Testing API endpoint..."
    if curl -s http://localhost:8080/api/health >/dev/null 2>&1; then
        echo "✅ Health endpoint working"
    else
        echo "❌ Health endpoint failed"
    fi

    if curl -s http://localhost:8080/api/config/defaults >/dev/null 2>&1; then
        echo "✅ Config defaults endpoint working"
    else
        echo "❌ Config defaults endpoint failed"
    fi

    # Get host IP
    HOST_IP=$(hostname -I | awk '{print $1}')
    echo "🌐 Web interface: http://${HOST_IP}:8080"
else
    echo "❌ Service failed to start"
    echo "💡 Check service status: systemctl status homelab-web-config"
    echo "💡 View logs: journalctl -u homelab-web-config -n 20"
fi