import React, { useState, useEffect } from 'react'
import { CheckCircle, Clock, AlertCircle, Play, Terminal } from 'lucide-react'
import { Navigate } from 'react-router-dom'
import api from '../utils/api'

const DeploymentProgress = ({ configuration, onDeploymentComplete }) => {
  const [deploymentStatus, setDeploymentStatus] = useState(null)
  const [logs, setLogs] = useState([])
  const [showLogs, setShowLogs] = useState(false)
  const [error, setError] = useState(null)

  useEffect(() => {
    if (!configuration) {
      return // Will redirect via React Router
    }

    startDeployment()
  }, [configuration])

  const startDeployment = async () => {
    try {
      const response = await api.post('/deployment/start')
      const deploymentId = response.data.deployment_id

      // Start polling for status
      pollDeploymentStatus(deploymentId)
    } catch (error) {
      console.error('Failed to start deployment:', error)
      setError('Failed to start deployment')
    }
  }

  const pollDeploymentStatus = async (deploymentId) => {
    const poll = async () => {
      try {
        const response = await api.get(`/deployment/status/${deploymentId}`)
        const status = response.data

        setDeploymentStatus(status)
        setLogs(status.logs || [])

        if (status.status === 'completed') {
          onDeploymentComplete(deploymentId)
        } else if (status.status === 'failed') {
          setError(status.error || 'Deployment failed')
        } else if (status.status === 'running' || status.status === 'starting') {
          // Continue polling
          setTimeout(poll, 2000)
        }
      } catch (error) {
        console.error('Failed to get deployment status:', error)
        setError('Failed to get deployment status')
      }
    }

    poll()
  }

  const getStepStatus = (stepName, currentStep, steps) => {
    if (!steps || steps.length === 0) return 'pending'

    const step = steps.find(s => s.name === stepName)
    if (!step) return 'pending'

    return step.status
  }

  const getStepIcon = (status) => {
    switch (status) {
      case 'completed':
        return <CheckCircle size={20} style={{ color: '#27ae60' }} />
      case 'running':
        return <Play size={20} style={{ color: '#3498db' }} />
      case 'failed':
        return <AlertCircle size={20} style={{ color: '#e74c3c' }} />
      default:
        return <Clock size={20} style={{ color: '#95a5a6' }} />
    }
  }

  const getStepClassName = (status) => {
    switch (status) {
      case 'completed':
        return 'progress-step completed'
      case 'running':
        return 'progress-step running'
      case 'failed':
        return 'progress-step failed'
      default:
        return 'progress-step'
    }
  }

  if (!configuration) {
    return <Navigate to="/" replace />
  }

  if (error) {
    return (
      <div className="progress-container">
        <div className="progress-header">
          <AlertCircle size={48} style={{ color: '#e74c3c', marginBottom: '20px' }} />
          <h2 className="progress-title">Deployment Failed</h2>
          <div className="progress-status" style={{ color: '#e74c3c' }}>
            {error}
          </div>
        </div>

        {logs.length > 0 && (
          <div style={{ marginTop: '30px' }}>
            <h4 style={{ marginBottom: '15px' }}>Deployment Logs</h4>
            <div className="logs-container">
              {logs.map((log, index) => (
                <div key={index} className="log-line">{log}</div>
              ))}
            </div>
          </div>
        )}

        <div style={{ textAlign: 'center', marginTop: '30px' }}>
          <button
            className="btn btn-primary"
            onClick={() => window.location.reload()}
          >
            Retry Deployment
          </button>
        </div>
      </div>
    )
  }

  const steps = [
    'Install Ansible collections',
    'Run Ansible playbook',
    'Apply Terraform/OpenTofu',
    'Verify deployment'
  ]

  return (
    <div className="progress-container">
      <div className="progress-header">
        <h2 className="progress-title">Deploying Your Home Lab</h2>
        <div className="progress-status">
          {deploymentStatus?.current_step || 'Initializing...'}
        </div>
      </div>

      <div className="progress-steps">
        {steps.map((stepName, index) => {
          const status = deploymentStatus ?
            getStepStatus(stepName, deploymentStatus.current_step, deploymentStatus.steps) :
            'pending'

          return (
            <div key={index} className={getStepClassName(status)}>
              <div className="step-icon">
                {getStepIcon(status)}
              </div>
              <div className="step-name">{stepName}</div>
              <div className="step-status">
                {status === 'running' ? 'In Progress...' :
                 status === 'completed' ? 'Complete' :
                 status === 'failed' ? 'Failed' : 'Pending'}
              </div>
            </div>
          )
        })}
      </div>

      {deploymentStatus && (
        <div style={{
          background: '#f8f9ff',
          border: '1px solid #e1e5e9',
          borderRadius: '8px',
          padding: '20px',
          marginBottom: '30px'
        }}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: '20px' }}>
            <div>
              <div style={{ fontWeight: '600', color: '#555' }}>Status</div>
              <div style={{ fontSize: '1.2rem', color: '#667eea', textTransform: 'capitalize' }}>
                {deploymentStatus.status}
              </div>
            </div>

            <div>
              <div style={{ fontWeight: '600', color: '#555' }}>Progress</div>
              <div style={{ fontSize: '1.2rem', color: '#667eea' }}>
                {deploymentStatus.steps_completed || 0} / {deploymentStatus.total_steps || 0} steps
              </div>
            </div>

            {deploymentStatus.started_at && (
              <div>
                <div style={{ fontWeight: '600', color: '#555' }}>Started</div>
                <div style={{ fontSize: '1.2rem', color: '#667eea' }}>
                  {new Date(deploymentStatus.started_at).toLocaleTimeString()}
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {logs.length > 0 && (
        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '15px' }}>
            <h4>Deployment Logs</h4>
            <button
              className="btn btn-secondary"
              onClick={() => setShowLogs(!showLogs)}
              style={{ display: 'flex', alignItems: 'center' }}
            >
              <Terminal size={16} style={{ marginRight: '8px' }} />
              {showLogs ? 'Hide Logs' : 'Show Logs'}
            </button>
          </div>

          {showLogs && (
            <div className="logs-container">
              {logs.map((log, index) => (
                <div key={index} className="log-line">{log}</div>
              ))}
            </div>
          )}
        </div>
      )}

      <div style={{
        background: '#e8f4fd',
        border: '1px solid #bee5eb',
        borderRadius: '8px',
        padding: '20px',
        marginTop: '30px'
      }}>
        <h4 style={{ marginBottom: '15px', color: '#0c5460' }}>
          What's happening now?
        </h4>
        <div style={{ color: '#0c5460', lineHeight: '1.6' }}>
          Your home lab is being automatically configured with Kubernetes, storage, networking,
          and all your selected services. This process typically takes 10-15 minutes depending
          on your internet connection and hardware.
        </div>

        <div style={{ marginTop: '15px', fontSize: '0.9rem', color: '#0c5460' }}>
          <strong>Tip:</strong> You can safely close this browser window and return later.
          The deployment will continue running in the background.
        </div>
      </div>
    </div>
  )
}

export default DeploymentProgress