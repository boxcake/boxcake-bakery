import React from 'react'
import { Container, Database, Globe, Wifi, GitBranch } from 'lucide-react'

const SERVICES = [
  {
    key: 'portainer',
    name: 'Portainer',
    description: 'Container management web UI for Docker and Kubernetes',
    icon: Container,
    recommended: true,
    dependencies: []
  },
  {
    key: 'registry',
    name: 'Docker Registry',
    description: 'Private container registry for storing your images',
    icon: Database,
    recommended: true,
    dependencies: []
  },
  {
    key: 'registry_ui',
    name: 'Registry UI',
    description: 'Web interface for browsing your private registry',
    icon: Globe,
    recommended: false,
    dependencies: ['registry']
  },
  {
    key: 'kubelish',
    name: 'Kubelish mDNS',
    description: 'Service discovery via mDNS for easy access to services',
    icon: Wifi,
    recommended: true,
    dependencies: []
  },
  {
    key: 'gitea',
    name: 'Gitea',
    description: 'Self-hosted Git service with web UI, issue tracking, and CI/CD',
    icon: GitBranch,
    recommended: false,
    dependencies: []
  }
]

const ServicesStep = ({ configuration, onUpdate }) => {
  const services = configuration.services || {}

  const handleServiceToggle = (serviceKey, enabled) => {
    const newServices = { ...services, [serviceKey]: enabled }

    // Handle dependencies
    if (!enabled) {
      // If disabling a service, also disable services that depend on it
      SERVICES.forEach(service => {
        if (service.dependencies.includes(serviceKey)) {
          newServices[service.key] = false
        }
      })
    } else {
      // If enabling a service, also enable its dependencies
      const service = SERVICES.find(s => s.key === serviceKey)
      if (service && service.dependencies) {
        service.dependencies.forEach(dep => {
          newServices[dep] = true
        })
      }
    }

    onUpdate({ services: newServices })
  }

  const isServiceDisabled = (serviceKey) => {
    // Check if any enabled service depends on this one
    return SERVICES.some(service =>
      services[service.key] &&
      service.dependencies.includes(serviceKey)
    )
  }

  const getEstimatedResources = () => {
    let cpu = 0
    let memory = 0

    if (services.portainer) {
      cpu += 0.1
      memory += 256
    }
    if (services.registry) {
      cpu += 0.1
      memory += 128
    }
    if (services.registry_ui) {
      cpu += 0.05
      memory += 64
    }
    if (services.kubelish) {
      cpu += 0.05
      memory += 32
    }
    if (services.gitea) {
      cpu += 0.2
      memory += 256
    }

    return { cpu, memory }
  }

  const resources = getEstimatedResources()

  return (
    <div>
      <div className="form-description" style={{ marginBottom: '30px' }}>
        Choose which services to deploy in your home lab. You can always add more services later.
      </div>

      <div className="checkbox-grid">
        {SERVICES.map((service) => {
          const Icon = service.icon
          const isEnabled = services[service.key] || false
          const isDisabled = isServiceDisabled(service.key) && !isEnabled

          return (
            <div
              key={service.key}
              className={`checkbox-item ${isEnabled ? 'checked' : ''}`}
              onClick={() => !isDisabled && handleServiceToggle(service.key, !isEnabled)}
              style={{
                opacity: isDisabled ? 0.6 : 1,
                cursor: isDisabled ? 'not-allowed' : 'pointer'
              }}
            >
              <input
                type="checkbox"
                checked={isEnabled}
                onChange={() => {}}
                disabled={isDisabled}
              />

              <div style={{ marginRight: '15px' }}>
                <Icon size={24} color={isEnabled ? '#667eea' : '#999'} />
              </div>

              <div className="checkbox-info" style={{ flex: 1 }}>
                <h4>
                  {service.name}
                  {service.recommended && (
                    <span style={{
                      marginLeft: '10px',
                      fontSize: '0.8rem',
                      background: '#27ae60',
                      color: 'white',
                      padding: '2px 8px',
                      borderRadius: '12px'
                    }}>
                      Recommended
                    </span>
                  )}
                  {isDisabled && (
                    <span style={{
                      marginLeft: '10px',
                      fontSize: '0.8rem',
                      background: '#f39c12',
                      color: 'white',
                      padding: '2px 8px',
                      borderRadius: '12px'
                    }}>
                      Required
                    </span>
                  )}
                </h4>
                <p>{service.description}</p>

                {service.dependencies.length > 0 && (
                  <div style={{
                    marginTop: '8px',
                    fontSize: '0.8rem',
                    color: '#666'
                  }}>
                    Requires: {service.dependencies.map(dep =>
                      SERVICES.find(s => s.key === dep)?.name
                    ).join(', ')}
                  </div>
                )}
              </div>
            </div>
          )
        })}
      </div>

      {Object.values(services).some(Boolean) && (
        <div style={{
          background: '#f8f9ff',
          border: '1px solid #e1e5e9',
          borderRadius: '8px',
          padding: '20px',
          marginTop: '30px'
        }}>
          <h4 style={{ marginBottom: '15px', color: '#333' }}>
            Estimated Resource Usage
          </h4>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
            <div>
              <div style={{ fontWeight: '600', color: '#555' }}>CPU</div>
              <div style={{ fontSize: '1.5rem', color: '#667eea' }}>
                ~{resources.cpu.toFixed(1)} cores
              </div>
            </div>

            <div>
              <div style={{ fontWeight: '600', color: '#555' }}>Memory</div>
              <div style={{ fontSize: '1.5rem', color: '#667eea' }}>
                ~{resources.memory} MB
              </div>
            </div>
          </div>

          <div style={{
            marginTop: '15px',
            fontSize: '0.9rem',
            color: '#666'
          }}>
            These are estimates based on typical usage. Actual resource consumption may vary.
          </div>
        </div>
      )}
    </div>
  )
}

export default ServicesStep