import React, { useState, useEffect } from 'react'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import ConfigurationWizard from './pages/ConfigurationWizard'
import DeploymentProgress from './pages/DeploymentProgress'
import CompletionPage from './pages/CompletionPage'
import './App.css'

const App = () => {
  const [currentStep, setCurrentStep] = useState('configure')
  const [configuration, setConfiguration] = useState(null)
  const [deploymentId, setDeploymentId] = useState(null)

  return (
    <div className="app">
      <div className="container">
        <header className="app-header">
          <h1>🏠 Home Lab Configuration</h1>
          <p>Set up your Kubernetes home lab with ease</p>
        </header>

        <Router>
          <Routes>
            <Route
              path="/"
              element={
                currentStep === 'configure' ? (
                  <ConfigurationWizard
                    onConfigurationComplete={(config) => {
                      setConfiguration(config)
                      setCurrentStep('deploy')
                    }}
                  />
                ) : currentStep === 'deploy' ? (
                  <Navigate to="/deploy" replace />
                ) : (
                  <Navigate to="/complete" replace />
                )
              }
            />

            <Route
              path="/deploy"
              element={
                <DeploymentProgress
                  configuration={configuration}
                  onDeploymentComplete={(id) => {
                    setDeploymentId(id)
                    setCurrentStep('complete')
                  }}
                />
              }
            />

            <Route
              path="/complete"
              element={
                <CompletionPage
                  deploymentId={deploymentId}
                  onStartOver={() => {
                    setCurrentStep('configure')
                    setConfiguration(null)
                    setDeploymentId(null)
                  }}
                />
              }
            />
          </Routes>
        </Router>
      </div>
    </div>
  )
}

export default App