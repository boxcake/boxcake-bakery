import React, { useState, useEffect } from 'react'
import { CheckCircle, ExternalLink, RefreshCw, Home } from 'lucide-react'

const CompletionPage = ({ deploymentId, onStartOver }) => {
  const [services, setServices] = useState([])
  const [hostIP, setHostIP] = useState('your-pi-ip')

  useEffect(() => {
    // In a real implementation, this would fetch the actual service URLs
    // For now, we'll use placeholder data
    detectHostIP()
    setServices([
      {
        name: 'Portainer',
        description: 'Container Management Interface',
        url: `http://${hostIP}:32090`,
        status: 'ready'
      },
      {
        name: 'Docker Registry',
        description: 'Private Container Registry',
        url: `http://${hostIP}:5000`,
        status: 'ready'
      },
      {
        name: 'Registry UI',
        description: 'Registry Web Interface',
        url: `http://${hostIP}:32080`,
        status: 'ready'
      }
    ])
  }, [hostIP])

  const detectHostIP = () => {
    // Try to detect the host IP from the current URL
    const currentHost = window.location.hostname
    if (currentHost && currentHost !== 'localhost') {
      setHostIP(currentHost)
    }
  }

  const testConnection = async (service) => {
    try {
      const response = await fetch(service.url, {
        method: 'HEAD',
        mode: 'no-cors',
        timeout: 5000
      })
      return true
    } catch (error) {
      console.log(`Service ${service.name} not yet ready:`, error)
      return false
    }
  }

  const testAllConnections = async () => {
    const updatedServices = await Promise.all(
      services.map(async (service) => {
        const isReady = await testConnection(service)
        return { ...service, status: isReady ? 'ready' : 'starting' }
      })
    )
    setServices(updatedServices)
  }

  return (
    <div className="completion-container">
      <div className="success-icon">
        <CheckCircle size={64} />
      </div>

      <h2 className="completion-title">
        🎉 Home Lab Deployed Successfully!
      </h2>

      <div className="completion-message">
        Your Kubernetes home lab is now running and ready to use.
        All services have been configured with your settings.
      </div>

      <div style={{ marginBottom: '40px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
          <h3 style={{ color: '#333' }}>Access Your Services</h3>
          <button
            className="btn btn-secondary"
            onClick={testAllConnections}
            style={{ display: 'flex', alignItems: 'center' }}
          >
            <RefreshCw size={16} style={{ marginRight: '8px' }} />
            Test Connections
          </button>
        </div>

        <div className="service-links">
          {services.map((service) => (
            <a
              key={service.name}
              href={service.url}
              target="_blank"
              rel="noopener noreferrer"
              className="service-link"
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '10px' }}>
                <h4>{service.name}</h4>
                <div style={{ display: 'flex', alignItems: 'center' }}>
                  <div style={{
                    width: '8px',
                    height: '8px',
                    borderRadius: '50%',
                    backgroundColor: service.status === 'ready' ? '#27ae60' : '#f39c12',
                    marginRight: '8px'
                  }} />
                  <ExternalLink size={16} />
                </div>
              </div>
              <p>{service.description}</p>
              <div style={{ fontSize: '0.85rem', color: '#666', fontFamily: 'monospace', marginTop: '8px' }}>
                {service.url}
              </div>
            </a>
          ))}
        </div>
      </div>

      <div style={{
        background: '#f8f9ff',
        border: '1px solid #e1e5e9',
        borderRadius: '8px',
        padding: '20px',
        marginBottom: '30px',
        textAlign: 'left'
      }}>
        <h4 style={{ marginBottom: '15px', color: '#333' }}>
          Next Steps
        </h4>
        <ul style={{ color: '#666', lineHeight: '1.8', paddingLeft: '20px' }}>
          <li>
            <strong>Access Portainer:</strong> Visit the Portainer URL above to manage your containers and deploy new applications
          </li>
          <li>
            <strong>Use the Registry:</strong> Configure your Docker client to push images to your private registry
          </li>
          <li>
            <strong>Add to /etc/hosts:</strong> Add entries like <code>{hostIP} portainer.local registry.local</code> for easier access
          </li>
          <li>
            <strong>SSH Access:</strong> Use <code>sudo -u homelab -i</code> to switch to the homelab management user
          </li>
          <li>
            <strong>Kubectl Access:</strong> Kubernetes config is available at <code>/etc/rancher/k3s/k3s.yaml</code>
          </li>
        </ul>
      </div>

      <div style={{
        background: '#e8f5e8',
        border: '1px solid #c3e6c3',
        borderRadius: '8px',
        padding: '20px',
        marginBottom: '30px',
        textAlign: 'left'
      }}>
        <h4 style={{ marginBottom: '15px', color: '#2d5a2d' }}>
          Helpful Commands
        </h4>
        <div style={{ fontFamily: 'monospace', fontSize: '0.9rem', color: '#2d5a2d' }}>
          <div style={{ marginBottom: '8px' }}>
            <code>kubectl get pods -A</code> - View all running pods
          </div>
          <div style={{ marginBottom: '8px' }}>
            <code>kubectl get svc -A</code> - View all services
          </div>
          <div style={{ marginBottom: '8px' }}>
            <code>docker push {hostIP}:5000/my-app:latest</code> - Push to registry
          </div>
          <div style={{ marginBottom: '8px' }}>
            <code>curl http://{hostIP}:5000/v2/_catalog</code> - List registry contents
          </div>
        </div>
      </div>

      <div style={{ display: 'flex', gap: '20px', justifyContent: 'center' }}>
        <button
          className="btn btn-secondary"
          onClick={onStartOver}
          style={{ display: 'flex', alignItems: 'center' }}
        >
          <Home size={16} style={{ marginRight: '8px' }} />
          Configure Another Lab
        </button>

        <a
          href={`http://${hostIP}:32090`}
          target="_blank"
          rel="noopener noreferrer"
          className="btn btn-primary"
          style={{ display: 'flex', alignItems: 'center' }}
        >
          <ExternalLink size={16} style={{ marginRight: '8px' }} />
          Open Portainer
        </a>
      </div>

      <div style={{
        marginTop: '40px',
        fontSize: '0.9rem',
        color: '#666',
        textAlign: 'center'
      }}>
        <p>
          Your home lab configuration has been saved and can be modified through the individual service interfaces.
        </p>
        <p>
          For advanced configuration, check the documentation at <code>/home/homelab/homelab-pi/docs/</code>
        </p>
      </div>
    </div>
  )
}

export default CompletionPage