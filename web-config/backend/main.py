#!/usr/bin/env python3
"""
FastAPI backend for Home Lab configuration interface
"""
import os
import asyncio
import subprocess
from pathlib import Path
from typing import Dict, Any, List
import yaml
import json
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, FileResponse
from pydantic import BaseModel, field_validator
import uvicorn

from config_generator import ConfigGenerator
from deployment import DeploymentManager

app = FastAPI(title="Home Lab Configuration API", version="1.0.0")

# Configuration models
class NetworkConfig(BaseModel):
    pod_cidr: str = "10.42.0.0/16"
    service_cidr: str = "10.43.0.0/16"
    homelab_pool: str = "10.43.0.0/20"
    user_pool: str = "10.43.16.0/20"

    @field_validator('pod_cidr', 'service_cidr', 'homelab_pool', 'user_pool')
    @classmethod
    def validate_cidr(cls, v):
        # Basic CIDR validation
        if not v or '/' not in v:
            raise ValueError('Invalid CIDR format')
        return v

class ServicesConfig(BaseModel):
    portainer: bool = True
    registry: bool = True
    registry_ui: bool = True
    kubelish: bool = True

class StorageConfig(BaseModel):
    portainer_size: str = "2Gi"
    registry_size: str = "10Gi"

class HomeLabConfig(BaseModel):
    admin_password: str
    services: ServicesConfig
    network: NetworkConfig
    storage: StorageConfig

    @field_validator('admin_password')
    @classmethod
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        return v

# Global state
config_generator = ConfigGenerator()
deployment_manager = DeploymentManager()
current_config: HomeLabConfig = None

# WebSocket connections for real-time updates
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def send_message(self, message: str):
        for connection in self.active_connections:
            try:
                await connection.send_text(message)
            except:
                await self.disconnect(connection)

manager = ConnectionManager()

# API endpoints
@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "message": "Home Lab Configuration API"}

@app.get("/api/config/defaults")
async def get_default_config():
    """Get default configuration values"""
    return HomeLabConfig(
        admin_password="",
        services=ServicesConfig(),
        network=NetworkConfig(),
        storage=StorageConfig()
    ).dict()

@app.post("/api/config/validate")
async def validate_config(config: HomeLabConfig):
    """Validate configuration without saving"""
    try:
        # Perform additional validation
        validation_errors = config_generator.validate_config(config.dict())
        if validation_errors:
            raise HTTPException(status_code=400, detail=validation_errors)

        return {"valid": True, "message": "Configuration is valid"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/api/config/save")
async def save_config(config: HomeLabConfig):
    """Save configuration and generate Ansible/Terraform files"""
    global current_config

    try:
        # Validate configuration
        validation_errors = config_generator.validate_config(config.dict())
        if validation_errors:
            raise HTTPException(status_code=400, detail=validation_errors)

        # Generate configuration files
        generated_files = await config_generator.generate_files(config.dict())

        # Store current config
        current_config = config

        return {
            "success": True,
            "message": "Configuration saved successfully",
            "generated_files": generated_files
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/deployment/start")
async def start_deployment():
    """Start the deployment process"""
    global current_config

    if not current_config:
        raise HTTPException(status_code=400, detail="No configuration saved")

    try:
        # Start deployment in background
        deployment_id = await deployment_manager.start_deployment(current_config.dict())

        return {
            "success": True,
            "deployment_id": deployment_id,
            "message": "Deployment started"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/deployment/status/{deployment_id}")
async def get_deployment_status(deployment_id: str):
    """Get deployment status"""
    try:
        status = await deployment_manager.get_status(deployment_id)
        return status
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.websocket("/ws/deployment")
async def websocket_deployment_logs(websocket: WebSocket):
    """WebSocket endpoint for real-time deployment logs"""
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            # Echo back for now - in real implementation, this would handle log streaming
            await websocket.send_text(f"Echo: {data}")
    except WebSocketDisconnect:
        manager.disconnect(websocket)

# Mount static files first (for JS, CSS, etc.)
build_dir = Path(__file__).parent.parent / "build"
if build_dir.exists() and (build_dir / "assets").exists():
    app.mount("/assets", StaticFiles(directory=build_dir / "assets"), name="assets")

# Serve static files (built React app)
@app.get("/")
async def serve_frontend():
    """Serve the main frontend application"""
    frontend_path = Path(__file__).parent.parent / "build" / "index.html"
    if frontend_path.exists():
        with open(frontend_path) as f:
            return HTMLResponse(content=f.read())
    else:
        return HTMLResponse(content="""
        <html>
            <body>
                <h1>Home Lab Configuration</h1>
                <p>Frontend not built yet. Please build the React application first.</p>
                <pre>cd web-config/frontend && npm run build</pre>
            </body>
        </html>
        """)

# Catch-all route for client-side routing and static files
@app.get("/{file_path:path}")
async def serve_static_files(file_path: str):
    """Serve static files or fall back to index.html for client-side routing"""
    build_dir = Path(__file__).parent.parent / "build"
    file_full_path = build_dir / file_path

    # If it's a file that exists, serve it
    if file_full_path.is_file():
        return FileResponse(file_full_path)

    # For client-side routing, serve index.html
    index_path = build_dir / "index.html"
    if index_path.exists():
        return FileResponse(index_path)

    # If nothing found, return 404
    raise HTTPException(status_code=404, detail="File not found")

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8080,
        reload=True,
        log_level="info"
    )