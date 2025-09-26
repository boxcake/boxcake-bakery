import React, { useState } from 'react'
import { Eye, EyeOff, AlertCircle, CheckCircle } from 'lucide-react'

const PasswordStep = ({ configuration, onUpdate }) => {
  const [showPassword, setShowPassword] = useState(false)
  const [passwordStrength, setPasswordStrength] = useState({ score: 0, feedback: [] })

  const checkPasswordStrength = (password) => {
    const checks = [
      { test: (p) => p.length >= 8, message: 'At least 8 characters' },
      { test: (p) => /[a-z]/.test(p), message: 'Contains lowercase letter' },
      { test: (p) => /[A-Z]/.test(p), message: 'Contains uppercase letter' },
      { test: (p) => /\d/.test(p), message: 'Contains number' },
      { test: (p) => /[!@#$%^&*(),.?":{}|<>]/.test(p), message: 'Contains special character' }
    ]

    const passedChecks = checks.filter(check => check.test(password))
    const failedChecks = checks.filter(check => !check.test(password))

    return {
      score: passedChecks.length,
      passed: passedChecks.map(c => c.message),
      failed: failedChecks.map(c => c.message)
    }
  }

  const handlePasswordChange = (e) => {
    const password = e.target.value
    const strength = checkPasswordStrength(password)
    setPasswordStrength(strength)

    onUpdate({ admin_password: password })
  }

  const getStrengthColor = (score) => {
    if (score < 2) return '#e74c3c'
    if (score < 4) return '#f39c12'
    return '#27ae60'
  }

  const getStrengthLabel = (score) => {
    if (score < 2) return 'Weak'
    if (score < 4) return 'Medium'
    return 'Strong'
  }

  return (
    <div>
      <div className="form-group">
        <label className="form-label">Admin Password</label>
        <div className="form-description">
          This will be the password for accessing Portainer and other admin interfaces.
          Choose a strong password to secure your home lab.
        </div>

        <div style={{ position: 'relative' }}>
          <input
            type={showPassword ? 'text' : 'password'}
            className="form-input"
            value={configuration.admin_password || ''}
            onChange={handlePasswordChange}
            placeholder="Enter a secure password"
            style={{ paddingRight: '50px' }}
          />

          <button
            type="button"
            onClick={() => setShowPassword(!showPassword)}
            style={{
              position: 'absolute',
              right: '15px',
              top: '50%',
              transform: 'translateY(-50%)',
              background: 'none',
              border: 'none',
              cursor: 'pointer',
              color: '#666'
            }}
          >
            {showPassword ? <EyeOff size={20} /> : <Eye size={20} />}
          </button>
        </div>

        {configuration.admin_password && (
          <div style={{ marginTop: '15px' }}>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              marginBottom: '10px'
            }}>
              <div style={{
                marginRight: '10px',
                color: getStrengthColor(passwordStrength.score)
              }}>
                Password Strength: {getStrengthLabel(passwordStrength.score)}
              </div>
              <div style={{
                flex: 1,
                height: '6px',
                backgroundColor: '#f0f0f0',
                borderRadius: '3px',
                overflow: 'hidden'
              }}>
                <div style={{
                  width: `${(passwordStrength.score / 5) * 100}%`,
                  height: '100%',
                  backgroundColor: getStrengthColor(passwordStrength.score),
                  transition: 'width 0.3s ease'
                }} />
              </div>
            </div>

            <div style={{ fontSize: '0.9rem' }}>
              {passwordStrength.passed.map((check, index) => (
                <div key={index} style={{
                  color: '#27ae60',
                  marginBottom: '5px',
                  display: 'flex',
                  alignItems: 'center'
                }}>
                  <CheckCircle size={16} style={{ marginRight: '8px' }} />
                  {check}
                </div>
              ))}

              {passwordStrength.failed.map((check, index) => (
                <div key={index} style={{
                  color: '#e74c3c',
                  marginBottom: '5px',
                  display: 'flex',
                  alignItems: 'center'
                }}>
                  <AlertCircle size={16} style={{ marginRight: '8px' }} />
                  {check}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      <div style={{
        background: '#f8f9ff',
        border: '1px solid #e1e5e9',
        borderRadius: '8px',
        padding: '20px',
        marginTop: '30px'
      }}>
        <h4 style={{ marginBottom: '15px', color: '#333' }}>
          Password Security Tips
        </h4>
        <ul style={{ color: '#666', lineHeight: '1.6' }}>
          <li>Use a unique password that you don't use elsewhere</li>
          <li>Consider using a password manager to generate and store strong passwords</li>
          <li>This password will be used for Portainer admin access</li>
          <li>You can change this password later through the Portainer interface</li>
        </ul>
      </div>
    </div>
  )
}

export default PasswordStep