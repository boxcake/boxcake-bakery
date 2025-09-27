import React from 'react'
import { HardDrive, Info } from 'lucide-react'

const STORAGE_PRESETS = [
  { label: 'Minimal', portainer: '1Gi', registry: '5Gi', gitea: '5Gi' },
  { label: 'Recommended', portainer: '2Gi', registry: '10Gi', gitea: '10Gi' },
  { label: 'Large', portainer: '5Gi', registry: '50Gi', gitea: '50Gi' }
]

const StorageStep = ({ configuration, onUpdate }) => {
  const storage = configuration.storage || {}

  const handleStorageChange = (field, value) => {
    onUpdate({
      storage: {
        ...storage,
        [field]: value
      }
    })
  }

  const applyPreset = (preset) => {
    onUpdate({
      storage: {
        portainer_size: preset.portainer,
        registry_size: preset.registry,
        gitea_size: preset.gitea
      }
    })
  }

  const validateStorageSize = (size) => {
    if (!size) return false
    const regex = /^\d+(\.\d+)?(Ei|Pi|Ti|Gi|Mi|Ki|E|P|T|G|M|K)$/
    return regex.test(size)
  }

  const parseStorageSize = (size) => {
    if (!validateStorageSize(size)) return 0

    const units = {
      'K': 1024,
      'Ki': 1024,
      'M': 1024 * 1024,
      'Mi': 1024 * 1024,
      'G': 1024 * 1024 * 1024,
      'Gi': 1024 * 1024 * 1024,
      'T': 1024 * 1024 * 1024 * 1024,
      'Ti': 1024 * 1024 * 1024 * 1024,
      'P': 1024 * 1024 * 1024 * 1024 * 1024,
      'Pi': 1024 * 1024 * 1024 * 1024 * 1024,
      'E': 1024 * 1024 * 1024 * 1024 * 1024 * 1024,
      'Ei': 1024 * 1024 * 1024 * 1024 * 1024 * 1024
    }

    const match = size.match(/^(\d+(?:\.\d+)?)([A-Za-z]+)$/)
    if (!match) return 0

    const value = parseFloat(match[1])
    const unit = match[2]

    return value * (units[unit] || 1)
  }

  const formatBytes = (bytes) => {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i]
  }

  const getTotalStorage = () => {
    const portainerBytes = parseStorageSize(storage.portainer_size || '0')
    const registryBytes = parseStorageSize(storage.registry_size || '0')
    const giteaBytes = parseStorageSize(storage.gitea_size || '0')
    return portainerBytes + registryBytes + giteaBytes
  }

  return (
    <div>
      <div className="form-description" style={{ marginBottom: '30px' }}>
        Configure storage sizes for your services. All data will be stored on persistent volumes
        using Longhorn distributed storage.
      </div>

      <div style={{ marginBottom: '30px' }}>
        <h4 style={{ marginBottom: '15px', color: '#333' }}>Quick Presets</h4>
        <div style={{ display: 'flex', gap: '15px', flexWrap: 'wrap' }}>
          {STORAGE_PRESETS.map((preset) => (
            <button
              key={preset.label}
              type="button"
              className="btn btn-secondary"
              onClick={() => applyPreset(preset)}
              style={{ minWidth: '120px' }}
            >
              {preset.label}
            </button>
          ))}
        </div>
      </div>

      <div className="network-grid">
        <div className="form-group">
          <label className="form-label">
            <HardDrive size={16} style={{ marginRight: '8px' }} />
            Portainer Storage
          </label>
          <div className="form-description">
            Storage for Portainer data and configuration
          </div>
          <input
            type="text"
            className={`form-input ${!validateStorageSize(storage.portainer_size) && storage.portainer_size ? 'error' : ''}`}
            value={storage.portainer_size || ''}
            onChange={(e) => handleStorageChange('portainer_size', e.target.value)}
            placeholder="2Gi"
          />
          {storage.portainer_size && (
            <div style={{ marginTop: '8px', fontSize: '0.9rem', color: '#666' }}>
              {validateStorageSize(storage.portainer_size) ? (
                <span style={{ color: '#27ae60' }}>
                  ✓ {formatBytes(parseStorageSize(storage.portainer_size))}
                </span>
              ) : (
                <span style={{ color: '#e74c3c' }}>
                  ✗ Invalid storage format (e.g., 2Gi, 500Mi)
                </span>
              )}
            </div>
          )}
        </div>

        <div className="form-group">
          <label className="form-label">
            <HardDrive size={16} style={{ marginRight: '8px' }} />
            Registry Storage
          </label>
          <div className="form-description">
            Storage for Docker images in your private registry
          </div>
          <input
            type="text"
            className={`form-input ${!validateStorageSize(storage.registry_size) && storage.registry_size ? 'error' : ''}`}
            value={storage.registry_size || ''}
            onChange={(e) => handleStorageChange('registry_size', e.target.value)}
            placeholder="10Gi"
          />
          {storage.registry_size && (
            <div style={{ marginTop: '8px', fontSize: '0.9rem', color: '#666' }}>
              {validateStorageSize(storage.registry_size) ? (
                <span style={{ color: '#27ae60' }}>
                  ✓ {formatBytes(parseStorageSize(storage.registry_size))}
                </span>
              ) : (
                <span style={{ color: '#e74c3c' }}>
                  ✗ Invalid storage format (e.g., 10Gi, 5000Mi)
                </span>
              )}
            </div>
          )}
        </div>

        <div className="form-group">
          <label className="form-label">
            <HardDrive size={16} style={{ marginRight: '8px' }} />
            Gitea Storage
          </label>
          <div className="form-description">
            Storage for Git repositories and Gitea data
          </div>
          <input
            type="text"
            className={`form-input ${!validateStorageSize(storage.gitea_size) && storage.gitea_size ? 'error' : ''}`}
            value={storage.gitea_size || ''}
            onChange={(e) => handleStorageChange('gitea_size', e.target.value)}
            placeholder="10Gi"
          />
          {storage.gitea_size && (
            <div style={{ marginTop: '8px', fontSize: '0.9rem', color: '#666' }}>
              {validateStorageSize(storage.gitea_size) ? (
                <span style={{ color: '#27ae60' }}>
                  ✓ {formatBytes(parseStorageSize(storage.gitea_size))}
                </span>
              ) : (
                <span style={{ color: '#e74c3c' }}>
                  ✗ Invalid storage format (e.g., 10Gi, 5000Mi)
                </span>
              )}
            </div>
          )}
        </div>
      </div>

      {(storage.portainer_size || storage.registry_size || storage.gitea_size) && (
        <div style={{
          background: '#f8f9ff',
          border: '1px solid #e1e5e9',
          borderRadius: '8px',
          padding: '20px',
          marginTop: '30px'
        }}>
          <h4 style={{ marginBottom: '15px', color: '#333' }}>
            Storage Summary
          </h4>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: '20px' }}>
            {storage.portainer_size && validateStorageSize(storage.portainer_size) && (
              <div>
                <div style={{ fontWeight: '600', color: '#555' }}>Portainer</div>
                <div style={{ fontSize: '1.2rem', color: '#667eea' }}>
                  {formatBytes(parseStorageSize(storage.portainer_size))}
                </div>
              </div>
            )}

            {storage.registry_size && validateStorageSize(storage.registry_size) && (
              <div>
                <div style={{ fontWeight: '600', color: '#555' }}>Registry</div>
                <div style={{ fontSize: '1.2rem', color: '#667eea' }}>
                  {formatBytes(parseStorageSize(storage.registry_size))}
                </div>
              </div>
            )}

            {storage.gitea_size && validateStorageSize(storage.gitea_size) && (
              <div>
                <div style={{ fontWeight: '600', color: '#555' }}>Gitea</div>
                <div style={{ fontSize: '1.2rem', color: '#667eea' }}>
                  {formatBytes(parseStorageSize(storage.gitea_size))}
                </div>
              </div>
            )}

            <div>
              <div style={{ fontWeight: '600', color: '#555' }}>Total</div>
              <div style={{ fontSize: '1.2rem', color: '#27ae60' }}>
                {formatBytes(getTotalStorage())}
              </div>
            </div>
          </div>
        </div>
      )}

      <div style={{
        background: '#e8f4fd',
        border: '1px solid #bee5eb',
        borderRadius: '8px',
        padding: '20px',
        marginTop: '30px',
        display: 'flex',
        alignItems: 'flex-start'
      }}>
        <Info size={20} style={{ color: '#0c5460', marginRight: '15px', marginTop: '2px' }} />
        <div>
          <h4 style={{ marginBottom: '10px', color: '#0c5460' }}>
            Storage Information
          </h4>
          <ul style={{ color: '#0c5460', lineHeight: '1.6', margin: 0, paddingLeft: '20px' }}>
            <li>Storage is provided by Longhorn distributed storage system</li>
            <li>All data persists across container restarts and updates</li>
            <li>You can expand storage sizes later if needed</li>
            <li>Use standard Kubernetes storage notation (Gi = gibibytes, Mi = mebibytes)</li>
          </ul>
        </div>
      </div>
    </div>
  )
}

export default StorageStep