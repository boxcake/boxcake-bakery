import React, { useState, useEffect } from 'react'
import { ChevronRight, ChevronLeft } from 'lucide-react'
import PasswordStep from '../components/PasswordStep'
import ServicesStep from '../components/ServicesStep'
import NetworkStep from '../components/NetworkStep'
import StorageStep from '../components/StorageStep'
import ReviewStep from '../components/ReviewStep'
import api from '../utils/api'

const STEPS = [
  { id: 'password', title: 'Admin Password', component: PasswordStep },
  { id: 'services', title: 'Select Services', component: ServicesStep },
  { id: 'network', title: 'Network Configuration', component: NetworkStep },
  { id: 'storage', title: 'Storage Settings', component: StorageStep },
  { id: 'review', title: 'Review & Deploy', component: ReviewStep }
]

const ConfigurationWizard = ({ onConfigurationComplete }) => {
  const [currentStepIndex, setCurrentStepIndex] = useState(0)
  const [configuration, setConfiguration] = useState({})
  const [errors, setErrors] = useState({})
  const [isLoading, setIsLoading] = useState(false)
  const [defaultConfig, setDefaultConfig] = useState(null)

  useEffect(() => {
    // Load default configuration
    const loadDefaults = async () => {
      try {
        const response = await api.get('/config/defaults')
        setDefaultConfig(response.data)
        setConfiguration(response.data)
      } catch (error) {
        console.error('Failed to load default configuration:', error)
      }
    }
    loadDefaults()
  }, [])

  const currentStep = STEPS[currentStepIndex]
  const CurrentStepComponent = currentStep.component

  const updateConfiguration = (stepData) => {
    setConfiguration(prev => ({
      ...prev,
      ...stepData
    }))
    setErrors({})
  }

  const validateCurrentStep = async () => {
    setIsLoading(true)
    try {
      await api.post('/config/validate', configuration)
      return true
    } catch (error) {
      if (error.response?.data?.detail) {
        setErrors({ general: error.response.data.detail })
      }
      return false
    } finally {
      setIsLoading(false)
    }
  }

  const nextStep = async () => {
    if (currentStepIndex === STEPS.length - 1) {
      // Final step - save configuration and start deployment
      await handleDeploy()
    } else {
      const isValid = await validateCurrentStep()
      if (isValid) {
        setCurrentStepIndex(prev => prev + 1)
      }
    }
  }

  const prevStep = () => {
    if (currentStepIndex > 0) {
      setCurrentStepIndex(prev => prev - 1)
    }
  }

  const handleDeploy = async () => {
    setIsLoading(true)
    try {
      // Save configuration
      await api.post('/config/save', configuration)

      // Start deployment
      const response = await api.post('/deployment/start')
      onConfigurationComplete(configuration, response.data.deployment_id)
    } catch (error) {
      console.error('Failed to start deployment:', error)
      setErrors({ general: 'Failed to start deployment. Please try again.' })
    } finally {
      setIsLoading(false)
    }
  }

  if (!defaultConfig) {
    return (
      <div className="wizard-container">
        <div style={{ textAlign: 'center', padding: '40px' }}>
          <div>Loading configuration...</div>
        </div>
      </div>
    )
  }

  return (
    <div className="wizard-container">
      <div className="step-header">
        <h2 className="step-title">{currentStep.title}</h2>
        <div className="step-counter">
          Step {currentStepIndex + 1} of {STEPS.length}
        </div>
      </div>

      {errors.general && (
        <div className="error-message" style={{ marginBottom: '20px' }}>
          {Array.isArray(errors.general) ? (
            <ul>
              {errors.general.map((error, index) => (
                <li key={index}>{error}</li>
              ))}
            </ul>
          ) : (
            errors.general
          )}
        </div>
      )}

      <CurrentStepComponent
        configuration={configuration}
        onUpdate={updateConfiguration}
        errors={errors}
      />

      <div className="wizard-actions">
        <button
          className="btn btn-secondary"
          onClick={prevStep}
          disabled={currentStepIndex === 0 || isLoading}
        >
          <ChevronLeft size={16} /> Previous
        </button>

        <button
          className="btn btn-primary"
          onClick={nextStep}
          disabled={isLoading}
        >
          {isLoading ? (
            'Processing...'
          ) : currentStepIndex === STEPS.length - 1 ? (
            'Deploy Now'
          ) : (
            <>
              Next <ChevronRight size={16} />
            </>
          )}
        </button>
      </div>
    </div>
  )
}

export default ConfigurationWizard