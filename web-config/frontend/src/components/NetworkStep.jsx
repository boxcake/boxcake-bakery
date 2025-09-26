import React, { useState } from 'react'
import { AlertCircle, Info, Network } from 'lucide-react'

const NetworkStep = ({ configuration, onUpdate, errors }) => {
  const [showAdvanced, setShowAdvanced] = useState(false)

  const network = configuration.network || {}

  const handleNetworkChange = (field, value) => {
    onUpdate({
      network: {
        ...network,
        [field]: value
      }
    })
  }

  const validateCIDR = (cidr) => {
    if (!cidr) return false
    const regex = /^(\d{1,3}\.){3}\d{1,3}\/\d{1,2}$/
    return regex.test(cidr)
  }

  const getIPRange = (cidr) => {
    if (!validateCIDR(cidr)) return null

    try {
      const [ip, prefix] = cidr.split('/')
      const prefixNum = parseInt(prefix)
      const ipParts = ip.split('.').map(Number)
      const totalIPs = Math.pow(2, 32 - prefixNum)

      return {
        totalIPs: totalIPs,
        usableIPs: totalIPs - 2, // Subtract network and broadcast
        firstIP: ip,
        description: totalIPs > 1000 ? `~${Math.floor(totalIPs / 1000)}k IPs` : `${totalIPs} IPs`
      }
    } catch (e) {
      return null
    }
  }

  return (
    <div>
      <div className="form-description" style={{ marginBottom: '30px' }}>
        Configure the network settings for your Kubernetes cluster. The defaults work well for most setups,
        but you can customize them if needed.
      </div>

      <div className="network-grid">
        <div className="form-group">
          <label className="form-label">
            Pod CIDR
            <Info size={16} style={{ marginLeft: '8px', color: '#666' }} />
          </label>
          <div className="form-description">
            IP range for Kubernetes pods (containers)
          </div>
          <input
            type="text"
            className={`form-input ${!validateCIDR(network.pod_cidr) && network.pod_cidr ? 'error' : ''}`}
            value={network.pod_cidr || ''}
            onChange={(e) => handleNetworkChange('pod_cidr', e.target.value)}
            placeholder="10.42.0.0/16"
          />
          {network.pod_cidr && (
            <div style={{ marginTop: '8px', fontSize: '0.9rem', color: '#666' }}>
              {validateCIDR(network.pod_cidr) ? (
                <span style={{ color: '#27ae60' }}>
                  ✓ {getIPRange(network.pod_cidr)?.description}
                </span>
              ) : (
                <span style={{ color: '#e74c3c' }}>
                  ✗ Invalid CIDR format
                </span>
              )}
            </div>
          )}
        </div>

        <div className="form-group">
          <label className="form-label">
            Service CIDR
            <Info size={16} style={{ marginLeft: '8px', color: '#666' }} />
          </label>
          <div className="form-description">
            IP range for Kubernetes services
          </div>
          <input
            type="text"
            className={`form-input ${!validateCIDR(network.service_cidr) && network.service_cidr ? 'error' : ''}`}
            value={network.service_cidr || ''}
            onChange={(e) => handleNetworkChange('service_cidr', e.target.value)}
            placeholder="10.43.0.0/16"
          />
          {network.service_cidr && (
            <div style={{ marginTop: '8px', fontSize: '0.9rem', color: '#666' }}>
              {validateCIDR(network.service_cidr) ? (
                <span style={{ color: '#27ae60' }}>
                  ✓ {getIPRange(network.service_cidr)?.description}
                </span>
              ) : (
                <span style={{ color: '#e74c3c' }}>
                  ✗ Invalid CIDR format
                </span>
              )}
            </div>
          )}
        </div>
      </div>

      <div style={{ marginTop: '30px' }}>
        <button
          type="button"
          className="btn btn-secondary"
          onClick={() => setShowAdvanced(!showAdvanced)}
          style={{ display: 'flex', alignItems: 'center' }}
        >
          <Network size={16} style={{ marginRight: '8px' }} />
          {showAdvanced ? 'Hide' : 'Show'} LoadBalancer Pools
        </button>
      </div>

      {showAdvanced && (
        <div style={{
          marginTop: '20px',
          padding: '20px',
          background: '#f8f9ff',
          border: '1px solid #e1e5e9',
          borderRadius: '8px'
        }}>
          <h4 style={{ marginBottom: '20px', color: '#333' }}>
            MetalLB LoadBalancer IP Pools
          </h4>

          <div className="network-grid">
            <div className="form-group">
              <label className="form-label">Homelab Pool</label>
              <div className="form-description">
                IP range for core infrastructure services (Portainer, Registry, etc.)
              </div>
              <input
                type="text"
                className={`form-input ${!validateCIDR(network.homelab_pool) && network.homelab_pool ? 'error' : ''}`}
                value={network.homelab_pool || ''}
                onChange={(e) => handleNetworkChange('homelab_pool', e.target.value)}
                placeholder="10.43.0.0/20"
              />
              {network.homelab_pool && (
                <div style={{ marginTop: '8px', fontSize: '0.9rem', color: '#666' }}>
                  {validateCIDR(network.homelab_pool) ? (
                    <span style={{ color: '#27ae60' }}>
                      ✓ {getIPRange(network.homelab_pool)?.description}
                    </span>
                  ) : (
                    <span style={{ color: '#e74c3c' }}>
                      ✗ Invalid CIDR format
                    </span>
                  )}
                </div>
              )}
            </div>

            <div className="form-group">
              <label className="form-label">User Pool</label>
              <div className="form-description">
                IP range for user applications and custom services
              </div>
              <input
                type="text"
                className={`form-input ${!validateCIDR(network.user_pool) && network.user_pool ? 'error' : ''}`}
                value={network.user_pool || ''}
                onChange={(e) => handleNetworkChange('user_pool', e.target.value)}
                placeholder="10.43.16.0/20"
              />
              {network.user_pool && (
                <div style={{ marginTop: '8px', fontSize: '0.9rem', color: '#666' }}>
                  {validateCIDR(network.user_pool) ? (
                    <span style={{ color: '#27ae60' }}>
                      ✓ {getIPRange(network.user_pool)?.description}
                    </span>
                  ) : (
                    <span style={{ color: '#e74c3c' }}>
                      ✗ Invalid CIDR format
                    </span>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      <div style={{
        background: '#fff3cd',
        border: '1px solid #ffeaa7',
        borderRadius: '8px',
        padding: '20px',
        marginTop: '30px',
        display: 'flex',
        alignItems: 'flex-start'
      }}>
        <AlertCircle size={20} style={{ color: '#856404', marginRight: '15px', marginTop: '2px' }} />
        <div>
          <h4 style={{ marginBottom: '10px', color: '#856404' }}>
            Network Configuration Tips
          </h4>
          <ul style={{ color: '#856404', lineHeight: '1.6', margin: 0, paddingLeft: '20px' }}>
            <li>Pod and Service CIDRs must not overlap with your existing network</li>
            <li>The default ranges work well for most home networks</li>
            <li>LoadBalancer pools must be within the Service CIDR range</li>
            <li>Make sure these ranges don't conflict with your router's DHCP pool</li>
          </ul>
        </div>
      </div>
    </div>
  )
}

export default NetworkStep