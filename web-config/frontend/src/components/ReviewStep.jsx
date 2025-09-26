import React from 'react'
import { CheckCircle, AlertCircle, Server, Shield, Network, HardDrive } from 'lucide-react'

const ReviewStep = ({ configuration }) => {
  const { admin_password, services, network, storage } = configuration

  const getServicesList = () => {
    const serviceNames = {
      portainer: 'Portainer (Container Management)',
      registry: 'Docker Registry',
      registry_ui: 'Registry UI',
      kubelish: 'Kubelish mDNS'
    }

    return Object.entries(services || {})
      .filter(([key, enabled]) => enabled)
      .map(([key, enabled]) => serviceNames[key] || key)
  }

  const validateConfiguration = () => {
    const issues = []

    if (!admin_password || admin_password.length < 8) {
      issues.push('Admin password must be at least 8 characters')
    }

    if (!services || !Object.values(services).some(Boolean)) {
      issues.push('At least one service must be selected')
    }

    return issues
  }

  const issues = validateConfiguration()
  const isValid = issues.length === 0

  return (
    <div>
      <div className="form-description" style={{ marginBottom: '30px' }}>
        Review your configuration before deployment. This will set up your entire home lab infrastructure.
      </div>

      {!isValid && (
        <div style={{
          background: '#fff5f5',
          border: '1px solid #fed7d7',
          borderRadius: '8px',
          padding: '20px',
          marginBottom: '30px',
          display: 'flex',
          alignItems: 'flex-start'
        }}>
          <AlertCircle size={20} style={{ color: '#e53e3e', marginRight: '15px', marginTop: '2px' }} />
          <div>
            <h4 style={{ marginBottom: '10px', color: '#e53e3e' }}>
              Configuration Issues
            </h4>
            <ul style={{ color: '#e53e3e', lineHeight: '1.6', margin: 0, paddingLeft: '20px' }}>
              {issues.map((issue, index) => (
                <li key={index}>{issue}</li>
              ))}
            </ul>
          </div>
        </div>
      )}

      <div style={{ display: 'grid', gap: '25px' }}>
        {/* Security Configuration */}
        <div style={{
          background: '#f8f9ff',
          border: '1px solid #e1e5e9',
          borderRadius: '8px',
          padding: '20px'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '15px' }}>
            <Shield size={20} style={{ color: '#667eea', marginRight: '12px' }} />
            <h4 style={{ color: '#333' }}>Security Configuration</h4>
          </div>

          <div style={{ display: 'grid', gap: '10px', fontSize: '0.95rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#666' }}>Admin Password:</span>
              <span style={{ color: '#333' }}>
                {'*'.repeat(admin_password?.length || 0)} ({admin_password?.length || 0} characters)
              </span>
            </div>
          </div>
        </div>

        {/* Services Configuration */}
        <div style={{
          background: '#f8f9ff',
          border: '1px solid #e1e5e9',
          borderRadius: '8px',
          padding: '20px'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '15px' }}>
            <Server size={20} style={{ color: '#667eea', marginRight: '12px' }} />
            <h4 style={{ color: '#333' }}>Services to Deploy</h4>
          </div>

          <div style={{ display: 'grid', gap: '8px' }}>
            {getServicesList().length > 0 ? (
              getServicesList().map((service, index) => (
                <div key={index} style={{ display: 'flex', alignItems: 'center' }}>
                  <CheckCircle size={16} style={{ color: '#27ae60', marginRight: '10px' }} />
                  <span style={{ color: '#333' }}>{service}</span>
                </div>
              ))
            ) : (
              <div style={{ color: '#e74c3c', fontStyle: 'italic' }}>
                No services selected
              </div>
            )}
          </div>
        </div>

        {/* Network Configuration */}
        <div style={{
          background: '#f8f9ff',
          border: '1px solid #e1e5e9',
          borderRadius: '8px',
          padding: '20px'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '15px' }}>
            <Network size={20} style={{ color: '#667eea', marginRight: '12px' }} />
            <h4 style={{ color: '#333' }}>Network Configuration</h4>
          </div>

          <div style={{ display: 'grid', gap: '10px', fontSize: '0.95rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#666' }}>Pod CIDR:</span>
              <span style={{ color: '#333', fontFamily: 'monospace' }}>
                {network?.pod_cidr || 'Not set'}
              </span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#666' }}>Service CIDR:</span>
              <span style={{ color: '#333', fontFamily: 'monospace' }}>
                {network?.service_cidr || 'Not set'}
              </span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#666' }}>Homelab Pool:</span>
              <span style={{ color: '#333', fontFamily: 'monospace' }}>
                {network?.homelab_pool || 'Not set'}
              </span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#666' }}>User Pool:</span>
              <span style={{ color: '#333', fontFamily: 'monospace' }}>
                {network?.user_pool || 'Not set'}
              </span>
            </div>
          </div>
        </div>

        {/* Storage Configuration */}
        <div style={{
          background: '#f8f9ff',
          border: '1px solid #e1e5e9',
          borderRadius: '8px',
          padding: '20px'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', marginBottom: '15px' }}>
            <HardDrive size={20} style={{ color: '#667eea', marginRight: '12px' }} />
            <h4 style={{ color: '#333' }}>Storage Configuration</h4>
          </div>

          <div style={{ display: 'grid', gap: '10px', fontSize: '0.95rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#666' }}>Portainer Storage:</span>
              <span style={{ color: '#333', fontFamily: 'monospace' }}>
                {storage?.portainer_size || 'Not set'}
              </span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ color: '#666' }}>Registry Storage:</span>
              <span style={{ color: '#333', fontFamily: 'monospace' }}>
                {storage?.registry_size || 'Not set'}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Deployment Information */}
      <div style={{
        background: '#e8f4fd',
        border: '1px solid #bee5eb',
        borderRadius: '8px',
        padding: '20px',
        marginTop: '30px'
      }}>
        <h4 style={{ marginBottom: '15px', color: '#0c5460' }}>
          What happens when you deploy?
        </h4>
        <ol style={{ color: '#0c5460', lineHeight: '1.6', paddingLeft: '20px' }}>
          <li>Generate configuration files for Ansible and OpenTofu</li>
          <li>Install and configure K3s Kubernetes cluster</li>
          <li>Set up Longhorn distributed storage</li>
          <li>Deploy MetalLB load balancer with your IP pools</li>
          <li>Deploy and configure selected services</li>
          <li>Configure service discovery with Kubelish (if enabled)</li>
          <li>Set up admin access to all services</li>
        </ol>

        <div style={{
          marginTop: '15px',
          padding: '15px',
          background: 'rgba(255, 255, 255, 0.7)',
          borderRadius: '6px'
        }}>
          <strong>Estimated deployment time: 10-15 minutes</strong>
          <br />
          <small>Time may vary depending on internet connection and hardware performance</small>
        </div>
      </div>
    </div>
  )
}

export default ReviewStep