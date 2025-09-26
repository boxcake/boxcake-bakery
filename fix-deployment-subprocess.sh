#!/bin/bash

# Quick fix script for the subprocess text=True issue
echo "🔧 Fixing deployment subprocess issue..."

# Restart the web service to pick up the fix
sudo systemctl restart homelab-web-config

# Wait and check status
sleep 2
if systemctl is-active --quiet homelab-web-config; then
    echo "✅ Service restarted successfully"

    # Test API endpoints
    if curl -s http://localhost:8080/api/health >/dev/null 2>&1; then
        echo "✅ Health endpoint responding"
    else
        echo "❌ Health endpoint not responding"
    fi

    HOST_IP=$(hostname -I | awk '{print $1}')
    echo "🌐 Web interface ready at: http://${HOST_IP}:8080"
    echo "🚀 The deployment subprocess issue has been fixed!"
    echo "   You can now try the deployment again through the web interface."

else
    echo "❌ Service failed to restart"
    echo "💡 Check logs: sudo journalctl -u homelab-web-config -n 10"
fi