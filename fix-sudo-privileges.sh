#!/bin/bash

# Fix the systemd service to allow sudo privileges
echo "🔧 Fixing systemd service sudo privileges..."

# Update the systemd service template
cat > /etc/systemd/system/homelab-web-config.service << 'EOF'
[Unit]
Description=Home Lab Web Configuration Interface
After=network.target

[Service]
Type=simple
User=homelab
Group=homelab
WorkingDirectory=/opt/homelab/web-config/backend
Environment=PATH=/opt/homelab/web-config/backend/venv/bin:/usr/local/bin:/usr/bin:/bin
Environment=PYTHONPATH=/opt/homelab/web-config/backend
ExecStart=/opt/homelab/web-config/backend/venv/bin/python main.py
Restart=always
RestartSec=5

# Security settings (relaxed to allow sudo)
NoNewPrivileges=false
ProtectSystem=false
ProtectHome=false
PrivateTmp=false

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd configuration
systemctl daemon-reload

# Restart the service
echo "🔄 Restarting web service..."
systemctl restart homelab-web-config

# Wait and check status
sleep 2
if systemctl is-active --quiet homelab-web-config; then
    echo "✅ Service restarted with sudo privileges enabled"

    # Test API endpoints
    if curl -s http://localhost:8080/api/health >/dev/null 2>&1; then
        echo "✅ Web service responding"
    else
        echo "❌ Web service not responding"
    fi

    HOST_IP=$(hostname -I | awk '{print $1}')
    echo "🌐 Web interface ready at: http://${HOST_IP}:8080"
    echo "🚀 Sudo privileges issue has been fixed!"
    echo "   The homelab user can now run sudo commands from the web service."

else
    echo "❌ Service failed to restart"
    echo "💡 Check logs: sudo journalctl -u homelab-web-config -n 10"
fi