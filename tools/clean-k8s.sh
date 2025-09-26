#!/bin/bash

# Clean Kubernetes Resources Script
# Removes Portainer and Registry UI deployments with all associated resources
# Handles persistent volumes and ensures complete cleanup

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
KUBECONFIG_PATH="/etc/rancher/k3s/k3s.yaml"
NAMESPACE="default"

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if kubectl is available
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please ensure Kubernetes is installed."
        exit 1
    fi

    if [[ ! -f "$KUBECONFIG_PATH" ]]; then
        log_error "Kubeconfig not found at $KUBECONFIG_PATH"
        exit 1
    fi

    # Test cluster connectivity
    if ! kubectl --kubeconfig="$KUBECONFIG_PATH" cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    log_success "Prerequisites checked"
}

# Show what will be cleaned up
show_cleanup_plan() {
    log_info "Scanning for resources to cleanup..."
    echo ""

    echo "🗑️  Resources that will be DELETED:"
    echo "=================================="

    # Portainer resources
    echo ""
    echo "📦 PORTAINER RESOURCES:"
    kubectl --kubeconfig="$KUBECONFIG_PATH" get deployment portainer -n "$NAMESPACE" 2>/dev/null && echo "  - Deployment: portainer" || true
    kubectl --kubeconfig="$KUBECONFIG_PATH" get service portainer-service -n "$NAMESPACE" 2>/dev/null && echo "  - Service: portainer-service" || true
    kubectl --kubeconfig="$KUBECONFIG_PATH" get pvc portainer-pvc -n "$NAMESPACE" 2>/dev/null && echo "  - PersistentVolumeClaim: portainer-pvc" || true
    kubectl --kubeconfig="$KUBECONFIG_PATH" get serviceaccount portainer-sa -n "$NAMESPACE" 2>/dev/null && echo "  - ServiceAccount: portainer-sa" || true
    kubectl --kubeconfig="$KUBECONFIG_PATH" get clusterrolebinding portainer-crb 2>/dev/null && echo "  - ClusterRoleBinding: portainer-crb" || true
    kubectl --kubeconfig="$KUBECONFIG_PATH" get job portainer-configure -n "$NAMESPACE" 2>/dev/null && echo "  - Job: portainer-configure" || true

    # Registry resources
    echo ""
    echo "🐳 REGISTRY RESOURCES:"
    kubectl --kubeconfig="$KUBECONFIG_PATH" get deployment registry -n "$NAMESPACE" 2>/dev/null && echo "  - Deployment: registry" || true
    kubectl --kubeconfig="$KUBECONFIG_PATH" get service registry-service -n "$NAMESPACE" 2>/dev/null && echo "  - Service: registry-service" || true
    kubectl --kubeconfig="$KUBECONFIG_PATH" get service registry-loadbalancer -n "$NAMESPACE" 2>/dev/null && echo "  - LoadBalancer: registry-loadbalancer" || true
    kubectl --kubeconfig="$KUBECONFIG_PATH" get pvc registry-pvc -n "$NAMESPACE" 2>/dev/null && echo "  - PersistentVolumeClaim: registry-pvc" || true

    # Registry UI resources
    echo ""
    echo "🖥️  REGISTRY UI RESOURCES:"
    kubectl --kubeconfig="$KUBECONFIG_PATH" get deployment registry-ui -n "$NAMESPACE" 2>/dev/null && echo "  - Deployment: registry-ui" || true
    kubectl --kubeconfig="$KUBECONFIG_PATH" get service registry-ui-service -n "$NAMESPACE" 2>/dev/null && echo "  - Service: registry-ui-service" || true

    # ConfigMaps
    echo ""
    echo "⚙️  CONFIGMAPS & SECRETS:"
    kubectl --kubeconfig="$KUBECONFIG_PATH" get configmap -n "$NAMESPACE" --no-headers 2>/dev/null | grep -E "(portainer|registry)" | awk '{print "  - ConfigMap: "$1}' || true
    kubectl --kubeconfig="$KUBECONFIG_PATH" get secret -n "$NAMESPACE" --no-headers 2>/dev/null | grep -E "(portainer|registry)" | awk '{print "  - Secret: "$1}' || true

    # Jobs
    echo ""
    echo "🔧 JOBS & CRONJOBS:"
    kubectl --kubeconfig="$KUBECONFIG_PATH" get jobs -n "$NAMESPACE" --no-headers 2>/dev/null | grep -E "(portainer|registry)" | awk '{print "  - Job: "$1}' || true
    kubectl --kubeconfig="$KUBECONFIG_PATH" get cronjobs -n "$NAMESPACE" --no-headers 2>/dev/null | grep -E "(portainer|registry)" | awk '{print "  - CronJob: "$1}' || true

    # Other Terraform-managed resources
    echo ""
    echo "📋 OTHER RESOURCES:"
    kubectl --kubeconfig="$KUBECONFIG_PATH" get ingress -n "$NAMESPACE" --no-headers 2>/dev/null | grep -E "(portainer|registry)" | awk '{print "  - Ingress: "$1}' || true
    kubectl --kubeconfig="$KUBECONFIG_PATH" get networkpolicy -n "$NAMESPACE" --no-headers 2>/dev/null | grep -E "(portainer|registry)" | awk '{print "  - NetworkPolicy: "$1}' || true

    # Check for persistent volumes
    echo ""
    echo "💾 PERSISTENT STORAGE:"
    local pv_count
    pv_count=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pv -o jsonpath='{.items[?(@.spec.claimRef.name=="portainer-pvc")].metadata.name}' 2>/dev/null | wc -w || echo "0")
    if [[ "$pv_count" -gt 0 ]]; then
        echo "  - PersistentVolume(s) bound to portainer-pvc: $pv_count"
        log_warning "Persistent volumes contain data that will be permanently lost!"
    else
        echo "  - No persistent volumes found for portainer"
    fi

    echo ""
}

# Clean up Portainer resources
cleanup_portainer() {
    log_info "Cleaning up Portainer resources..."

    # Remove configuration job first (might be running)
    if kubectl --kubeconfig="$KUBECONFIG_PATH" get job portainer-configure -n "$NAMESPACE" &> /dev/null; then
        log_info "Deleting Portainer configuration job..."
        kubectl --kubeconfig="$KUBECONFIG_PATH" delete job portainer-configure -n "$NAMESPACE" --ignore-not-found=true
        log_success "Portainer configuration job deleted"
    fi

    # Remove deployment
    if kubectl --kubeconfig="$KUBECONFIG_PATH" get deployment portainer -n "$NAMESPACE" &> /dev/null; then
        log_info "Deleting Portainer deployment..."
        kubectl --kubeconfig="$KUBECONFIG_PATH" delete deployment portainer -n "$NAMESPACE" --ignore-not-found=true
        log_success "Portainer deployment deleted"
    fi

    # Remove service
    if kubectl --kubeconfig="$KUBECONFIG_PATH" get service portainer-service -n "$NAMESPACE" &> /dev/null; then
        log_info "Deleting Portainer service..."
        kubectl --kubeconfig="$KUBECONFIG_PATH" delete service portainer-service -n "$NAMESPACE" --ignore-not-found=true
        log_success "Portainer service deleted"
    fi

    # Remove PVC (this will also trigger PV deletion if dynamically provisioned)
    if kubectl --kubeconfig="$KUBECONFIG_PATH" get pvc portainer-pvc -n "$NAMESPACE" &> /dev/null; then
        log_warning "Deleting Portainer persistent volume claim (data will be lost)..."
        kubectl --kubeconfig="$KUBECONFIG_PATH" delete pvc portainer-pvc -n "$NAMESPACE" --ignore-not-found=true
        log_success "Portainer PVC deleted"

        # Wait a moment for PV cleanup
        log_info "Waiting for persistent volume cleanup..."
        sleep 5
    fi

    # Remove ServiceAccount
    if kubectl --kubeconfig="$KUBECONFIG_PATH" get serviceaccount portainer-sa -n "$NAMESPACE" &> /dev/null; then
        log_info "Deleting Portainer service account..."
        kubectl --kubeconfig="$KUBECONFIG_PATH" delete serviceaccount portainer-sa -n "$NAMESPACE" --ignore-not-found=true
        log_success "Portainer service account deleted"
    fi

    # Remove ClusterRoleBinding
    if kubectl --kubeconfig="$KUBECONFIG_PATH" get clusterrolebinding portainer-crb &> /dev/null; then
        log_info "Deleting Portainer cluster role binding..."
        kubectl --kubeconfig="$KUBECONFIG_PATH" delete clusterrolebinding portainer-crb --ignore-not-found=true
        log_success "Portainer cluster role binding deleted"
    fi
}

# Clean up Registry resources
cleanup_registry() {
    log_info "Cleaning up Registry resources..."

    # Remove deployment
    if kubectl --kubeconfig="$KUBECONFIG_PATH" get deployment registry -n "$NAMESPACE" &> /dev/null; then
        log_info "Deleting Registry deployment..."
        kubectl --kubeconfig="$KUBECONFIG_PATH" delete deployment registry -n "$NAMESPACE" --ignore-not-found=true
        log_success "Registry deployment deleted"
    fi

    # Remove services
    if kubectl --kubeconfig="$KUBECONFIG_PATH" get service registry-service -n "$NAMESPACE" &> /dev/null; then
        log_info "Deleting Registry service..."
        kubectl --kubeconfig="$KUBECONFIG_PATH" delete service registry-service -n "$NAMESPACE" --ignore-not-found=true
        log_success "Registry service deleted"
    fi

    if kubectl --kubeconfig="$KUBECONFIG_PATH" get service registry-loadbalancer -n "$NAMESPACE" &> /dev/null; then
        log_info "Deleting Registry LoadBalancer service..."
        kubectl --kubeconfig="$KUBECONFIG_PATH" delete service registry-loadbalancer -n "$NAMESPACE" --ignore-not-found=true
        log_success "Registry LoadBalancer deleted"
    fi

    # Remove PVC (this will also trigger PV deletion if dynamically provisioned)
    if kubectl --kubeconfig="$KUBECONFIG_PATH" get pvc registry-pvc -n "$NAMESPACE" &> /dev/null; then
        log_warning "Deleting Registry persistent volume claim (data will be lost)..."
        kubectl --kubeconfig="$KUBECONFIG_PATH" delete pvc registry-pvc -n "$NAMESPACE" --ignore-not-found=true
        log_success "Registry PVC deleted"

        # Wait a moment for PV cleanup
        log_info "Waiting for persistent volume cleanup..."
        sleep 5
    fi
}

# Clean up Registry UI resources
cleanup_registry_ui() {
    log_info "Cleaning up Registry UI resources..."

    # Remove deployment
    if kubectl --kubeconfig="$KUBECONFIG_PATH" get deployment registry-ui -n "$NAMESPACE" &> /dev/null; then
        log_info "Deleting Registry UI deployment..."
        kubectl --kubeconfig="$KUBECONFIG_PATH" delete deployment registry-ui -n "$NAMESPACE" --ignore-not-found=true
        log_success "Registry UI deployment deleted"
    fi

    # Remove service
    if kubectl --kubeconfig="$KUBECONFIG_PATH" get service registry-ui-service -n "$NAMESPACE" &> /dev/null; then
        log_info "Deleting Registry UI service..."
        kubectl --kubeconfig="$KUBECONFIG_PATH" delete service registry-ui-service -n "$NAMESPACE" --ignore-not-found=true
        log_success "Registry UI service deleted"
    fi
}

# Clean up ConfigMaps, Secrets, and other resources
cleanup_additional_resources() {
    log_info "Cleaning up ConfigMaps, Secrets, and other resources..."

    # Remove ConfigMaps related to portainer/registry
    local configmaps
    configmaps=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get configmap -n "$NAMESPACE" --no-headers 2>/dev/null | grep -E "(portainer|registry)" | awk '{print $1}' || echo "")

    if [[ -n "$configmaps" ]]; then
        for cm in $configmaps; do
            log_info "Deleting ConfigMap: $cm"
            kubectl --kubeconfig="$KUBECONFIG_PATH" delete configmap "$cm" -n "$NAMESPACE" --ignore-not-found=true
            log_success "ConfigMap $cm deleted"
        done
    else
        log_success "No ConfigMaps to clean up"
    fi

    # Remove Secrets related to portainer/registry
    local secrets
    secrets=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get secret -n "$NAMESPACE" --no-headers 2>/dev/null | grep -E "(portainer|registry)" | awk '{print $1}' || echo "")

    if [[ -n "$secrets" ]]; then
        for secret in $secrets; do
            log_info "Deleting Secret: $secret"
            kubectl --kubeconfig="$KUBECONFIG_PATH" delete secret "$secret" -n "$NAMESPACE" --ignore-not-found=true
            log_success "Secret $secret deleted"
        done
    else
        log_success "No Secrets to clean up"
    fi

    # Remove Jobs related to portainer/registry
    local jobs
    jobs=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get jobs -n "$NAMESPACE" --no-headers 2>/dev/null | grep -E "(portainer|registry)" | awk '{print $1}' || echo "")

    if [[ -n "$jobs" ]]; then
        for job in $jobs; do
            log_info "Deleting Job: $job"
            kubectl --kubeconfig="$KUBECONFIG_PATH" delete job "$job" -n "$NAMESPACE" --ignore-not-found=true
            log_success "Job $job deleted"
        done
    else
        log_success "No Jobs to clean up"
    fi

    # Remove CronJobs related to portainer/registry
    local cronjobs
    cronjobs=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get cronjobs -n "$NAMESPACE" --no-headers 2>/dev/null | grep -E "(portainer|registry)" | awk '{print $1}' || echo "")

    if [[ -n "$cronjobs" ]]; then
        for cronjob in $cronjobs; do
            log_info "Deleting CronJob: $cronjob"
            kubectl --kubeconfig="$KUBECONFIG_PATH" delete cronjob "$cronjob" -n "$NAMESPACE" --ignore-not-found=true
            log_success "CronJob $cronjob deleted"
        done
    else
        log_success "No CronJobs to clean up"
    fi

    # Remove Ingresses related to portainer/registry
    local ingresses
    ingresses=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get ingress -n "$NAMESPACE" --no-headers 2>/dev/null | grep -E "(portainer|registry)" | awk '{print $1}' || echo "")

    if [[ -n "$ingresses" ]]; then
        for ingress in $ingresses; do
            log_info "Deleting Ingress: $ingress"
            kubectl --kubeconfig="$KUBECONFIG_PATH" delete ingress "$ingress" -n "$NAMESPACE" --ignore-not-found=true
            log_success "Ingress $ingress deleted"
        done
    else
        log_success "No Ingresses to clean up"
    fi
}

# Clean up any orphaned persistent volumes
cleanup_orphaned_volumes() {
    log_info "Checking for orphaned persistent volumes..."

    local orphaned_pvs
    orphaned_pvs=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pv -o jsonpath='{.items[?(@.spec.claimRef.name=="portainer-pvc")].metadata.name}' 2>/dev/null || echo "")

    if [[ -n "$orphaned_pvs" ]]; then
        for pv in $orphaned_pvs; do
            log_info "Found orphaned persistent volume: $pv"
            kubectl --kubeconfig="$KUBECONFIG_PATH" delete pv "$pv" --ignore-not-found=true
            log_success "Orphaned persistent volume $pv deleted"
        done
    else
        log_success "No orphaned persistent volumes found"
    fi
}

# Clean up Terraform state and related files
cleanup_terraform_state() {
    log_info "Cleaning up Terraform/OpenTofu state..."

    local terraform_dir="/opt/homelab/terraform"
    if [[ -d "$terraform_dir" ]]; then
        log_info "Found Terraform directory at $terraform_dir"

        # Remove state files
        if [[ -f "$terraform_dir/terraform.tfstate" ]]; then
            log_warning "Removing Terraform state file (this will lose track of infrastructure)"
            rm -f "$terraform_dir/terraform.tfstate" "$terraform_dir/terraform.tfstate.backup"
            log_success "Terraform state files deleted"
        fi

        # Remove plan files
        if [[ -f "$terraform_dir/tfplan" ]]; then
            log_info "Removing Terraform plan files"
            rm -f "$terraform_dir/tfplan"
            log_success "Terraform plan files deleted"
        fi

        # Remove .terraform directory
        if [[ -d "$terraform_dir/.terraform" ]]; then
            log_info "Removing Terraform working directory"
            rm -rf "$terraform_dir/.terraform"
            log_success "Terraform working directory deleted"
        fi

        # Remove lock file
        if [[ -f "$terraform_dir/.terraform.lock.hcl" ]]; then
            log_info "Removing Terraform lock file"
            rm -f "$terraform_dir/.terraform.lock.hcl"
            log_success "Terraform lock file deleted"
        fi
    else
        log_success "No Terraform directory found at $terraform_dir"
    fi

    # Also clean up any terraform files in current directory
    if [[ -f "./terraform.tfstate" ]]; then
        log_info "Removing local Terraform state files"
        rm -f ./terraform.tfstate ./terraform.tfstate.backup ./tfplan
        rm -rf ./.terraform
        rm -f ./.terraform.lock.hcl
        log_success "Local Terraform files deleted"
    fi
}

# Wait for pod termination
wait_for_cleanup() {
    log_info "Waiting for pods to terminate..."

    local max_wait=60
    local count=0

    while [[ $count -lt $max_wait ]]; do
        local portainer_pods
        local registry_pods
        local registry_ui_pods

        portainer_pods=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods -l app=portainer -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l || echo "0")
        registry_pods=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods -l app=registry -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l || echo "0")
        registry_ui_pods=$(kubectl --kubeconfig="$KUBECONFIG_PATH" get pods -l app=registry-ui -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l || echo "0")

        if [[ "$portainer_pods" -eq 0 && "$registry_pods" -eq 0 && "$registry_ui_pods" -eq 0 ]]; then
            log_success "All pods terminated successfully"
            return 0
        fi

        echo -n "."
        sleep 2
        count=$((count + 2))
    done

    echo ""
    log_warning "Some pods may still be terminating"
}

# Verify cleanup
verify_cleanup() {
    log_info "Verifying cleanup..."

    local remaining_resources=0

    # Check for remaining Portainer resources
    if kubectl --kubeconfig="$KUBECONFIG_PATH" get deployment portainer -n "$NAMESPACE" &> /dev/null; then
        log_warning "Portainer deployment still exists"
        ((remaining_resources++))
    fi

    if kubectl --kubeconfig="$KUBECONFIG_PATH" get service portainer-service -n "$NAMESPACE" &> /dev/null; then
        log_warning "Portainer service still exists"
        ((remaining_resources++))
    fi

    if kubectl --kubeconfig="$KUBECONFIG_PATH" get pvc portainer-pvc -n "$NAMESPACE" &> /dev/null; then
        log_warning "Portainer PVC still exists"
        ((remaining_resources++))
    fi

    # Check for remaining Registry resources
    if kubectl --kubeconfig="$KUBECONFIG_PATH" get deployment registry -n "$NAMESPACE" &> /dev/null; then
        log_warning "Registry deployment still exists"
        ((remaining_resources++))
    fi

    if kubectl --kubeconfig="$KUBECONFIG_PATH" get service registry-service -n "$NAMESPACE" &> /dev/null; then
        log_warning "Registry service still exists"
        ((remaining_resources++))
    fi

    if kubectl --kubeconfig="$KUBECONFIG_PATH" get pvc registry-pvc -n "$NAMESPACE" &> /dev/null; then
        log_warning "Registry PVC still exists"
        ((remaining_resources++))
    fi

    # Check for remaining Registry UI resources
    if kubectl --kubeconfig="$KUBECONFIG_PATH" get deployment registry-ui -n "$NAMESPACE" &> /dev/null; then
        log_warning "Registry UI deployment still exists"
        ((remaining_resources++))
    fi

    if kubectl --kubeconfig="$KUBECONFIG_PATH" get service registry-ui-service -n "$NAMESPACE" &> /dev/null; then
        log_warning "Registry UI service still exists"
        ((remaining_resources++))
    fi

    if [[ $remaining_resources -eq 0 ]]; then
        log_success "Cleanup verification passed - all resources removed"
    else
        log_warning "Cleanup verification found $remaining_resources remaining resources"
        log_info "You may need to manually clean up remaining resources"
    fi
}

# Main execution
main() {
    echo "🧹 Kubernetes Resource Cleanup Tool"
    echo "==================================="
    echo ""

    check_prerequisites
    show_cleanup_plan

    echo ""
    log_warning "This will PERMANENTLY DELETE all Portainer and Registry UI resources!"
    log_warning "All data stored in persistent volumes will be LOST!"
    echo ""

    read -p "❓ Are you sure you want to proceed? (type 'yes' to confirm): " -r
    echo ""

    if [[ ! "$REPLY" == "yes" ]]; then
        log_info "Cleanup cancelled by user"
        exit 0
    fi

    log_info "Starting cleanup process..."
    echo ""

    cleanup_portainer
    echo ""
    cleanup_registry
    echo ""
    cleanup_registry_ui
    echo ""
    cleanup_additional_resources
    echo ""
    cleanup_terraform_state
    echo ""
    cleanup_orphaned_volumes
    echo ""
    wait_for_cleanup
    echo ""
    verify_cleanup

    echo ""
    log_success "🎉 Cleanup completed successfully!"
    echo ""
    echo "📋 Summary:"
    echo "  - Portainer deployment and associated resources removed"
    echo "  - Docker Registry deployment and associated resources removed"
    echo "  - Registry UI deployment and associated resources removed"
    echo "  - Persistent volumes and data deleted"
    echo "  - RBAC resources cleaned up"
    echo ""
}

# Handle script interruption
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"