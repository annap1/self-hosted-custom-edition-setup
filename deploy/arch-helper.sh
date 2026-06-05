#!/usr/bin/env bash
# (c) Copyright IBM Corp. 2025
# Architecture detection and validation helper for Linux on Z (s390x)

# Detect the current system architecture
detect_architecture() {
  local arch
  arch=$(uname -m)
  echo "$arch"
}

# Validate if the architecture is supported
validate_architecture() {
  local arch
  arch=$(detect_architecture)
  
  case "$arch" in
    x86_64|amd64)
      info "Detected architecture: x86_64/amd64"
      export INSTANA_ARCH="amd64"
      ;;
    s390x)
      info "Detected architecture: s390x (Linux on Z)"
      export INSTANA_ARCH="s390x"
      ;;
    aarch64|arm64)
      info "Detected architecture: aarch64/arm64"
      export INSTANA_ARCH="arm64"
      ;;
    ppc64le)
      info "Detected architecture: ppc64le (Power)"
      export INSTANA_ARCH="ppc64le"
      ;;
    *)
      warn "Unsupported architecture detected: $arch"
      warn "Instana Self-Hosted Custom Edition officially supports: x86_64, s390x, aarch64, ppc64le"
      error "Please verify architecture compatibility before proceeding."
      ;;
  esac
}

# Check if running on Linux on Z
is_linux_on_z() {
  local arch
  arch=$(detect_architecture)
  [[ "$arch" == "s390x" ]]
}

# Get architecture-specific kubectl binary URL
get_kubectl_download_url() {
  local version=$1
  local arch
  arch=$(detect_architecture)
  
  case "$arch" in
    x86_64|amd64)
      echo "https://dl.k8s.io/release/${version}/bin/linux/amd64/kubectl"
      ;;
    s390x)
      echo "https://dl.k8s.io/release/${version}/bin/linux/s390x/kubectl"
      ;;
    aarch64|arm64)
      echo "https://dl.k8s.io/release/${version}/bin/linux/arm64/kubectl"
      ;;
    ppc64le)
      echo "https://dl.k8s.io/release/${version}/bin/linux/ppc64le/kubectl"
      ;;
    *)
      error "Cannot determine kubectl download URL for architecture: $arch"
      ;;
  esac
}

# Validate kubectl binary architecture
validate_kubectl_architecture() {
  if ! command -v kubectl &> /dev/null; then
    warn "kubectl is not installed. Please install kubectl for your architecture."
    return 1
  fi
  
  local kubectl_version
  kubectl_version=$(kubectl version --client=true --output=json 2>/dev/null | grep -o '"platform":"[^"]*"' | cut -d'"' -f4)
  
  if [[ -z "$kubectl_version" ]]; then
    warn "Could not determine kubectl architecture. Proceeding with caution."
    return 0
  fi
  
  local system_arch
  system_arch=$(detect_architecture)
  
  info "kubectl platform: $kubectl_version, system architecture: $system_arch"
  
  # Normalize architecture names for comparison
  case "$kubectl_version" in
    *s390x*)
      if [[ "$system_arch" != "s390x" ]]; then
        warn "kubectl architecture mismatch detected"
      fi
      ;;
    *amd64*|*x86_64*)
      if [[ "$system_arch" != "x86_64" && "$system_arch" != "amd64" ]]; then
        warn "kubectl architecture mismatch detected"
      fi
      ;;
    *arm64*|*aarch64*)
      if [[ "$system_arch" != "aarch64" && "$system_arch" != "arm64" ]]; then
        warn "kubectl architecture mismatch detected"
      fi
      ;;
    *ppc64le*)
      if [[ "$system_arch" != "ppc64le" ]]; then
        warn "kubectl architecture mismatch detected"
      fi
      ;;
  esac
}

# Check for s390x-specific system requirements
check_s390x_requirements() {
  if ! is_linux_on_z; then
    return 0
  fi
  
  info "Performing Linux on Z (s390x) specific checks..."
  
  # Check for sufficient memory (s390x systems typically have different memory configurations)
  local total_mem_kb
  total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  local total_mem_gb=$((total_mem_kb / 1024 / 1024))
  
  if [[ $total_mem_gb -lt 32 ]]; then
    warn "System has ${total_mem_gb}GB of memory. Instana recommends at least 32GB for production deployments."
  else
    info "System memory: ${total_mem_gb}GB - OK"
  fi
  
  # Check for CPU architecture features
  if [[ -f /proc/cpuinfo ]]; then
    local cpu_count
    cpu_count=$(grep -c ^processor /proc/cpuinfo)
    info "Detected ${cpu_count} CPU cores"
    
    if [[ $cpu_count -lt 8 ]]; then
      warn "System has ${cpu_count} CPU cores. Instana recommends at least 8 cores for production deployments."
    fi
  fi
  
  # Check for required kernel modules on s390x
  if ! lsmod | grep -q "^dm_mod"; then
    warn "Device mapper kernel module (dm_mod) not loaded. This may be required for some storage configurations."
  fi
  
  info "Linux on Z (s390x) system checks completed."
}

# Get architecture-specific image suffix for multi-arch images
get_image_arch_suffix() {
  local arch
  arch=$(detect_architecture)
  
  # Most Instana images are multi-arch and don't need a suffix
  # This function is here for future use if specific images need arch suffixes
  echo ""
}

# Validate that the Kubernetes cluster nodes support the required architecture
validate_cluster_architecture() {
  info "Validating Kubernetes cluster node architectures..."
  
  local node_archs
  node_archs=$(kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.architecture}' 2>/dev/null | tr ' ' '\n' | sort -u)
  
  if [[ -z "$node_archs" ]]; then
    warn "Could not determine cluster node architectures"
    return 0
  fi
  
  local system_arch
  system_arch=$(detect_architecture)
  
  info "Cluster node architectures: $(echo "$node_archs" | tr '\n' ' ')"
  
  # Check if cluster has nodes matching the system architecture
  if echo "$node_archs" | grep -q "$system_arch"; then
    info "Cluster has nodes matching system architecture ($system_arch) - OK"
  else
    warn "Cluster nodes do not match system architecture ($system_arch)"
    warn "This may cause issues if images are not multi-architecture"
  fi
  
  # Special check for s390x
  if is_linux_on_z; then
    if ! echo "$node_archs" | grep -q "s390x"; then
      error "Running on s390x system but cluster has no s390x nodes. Cannot proceed."
    fi
    info "Confirmed s390x nodes in cluster - OK"
  fi
}

# Print architecture-specific installation notes
print_arch_notes() {
  if is_linux_on_z; then
    echo ""
    echo "==============================================================================="
    echo "  Linux on Z (s390x) Installation Notes"
    echo "==============================================================================="
    echo ""
    echo "  • Ensure all container images support s390x architecture"
    echo "  • Verify that your container registry has s390x image variants"
    echo "  • Some third-party components may have limited s390x support"
    echo "  • Review IBM documentation for s390x-specific configuration requirements"
    echo "  • Consider using IBM Cloud Pak for s390x optimized deployments"
    echo ""
    echo "  For more information, visit:"
    echo "  https://www.ibm.com/docs/en/instana-observability/current"
    echo ""
    echo "==============================================================================="
    echo ""
  fi
}

# Export architecture information for use in other scripts
export_arch_info() {
  export INSTANA_SYSTEM_ARCH=$(detect_architecture)
  export INSTANA_IS_S390X=$(is_linux_on_z && echo "true" || echo "false")
  
  info "Architecture information exported:"
  info "  INSTANA_SYSTEM_ARCH=$INSTANA_SYSTEM_ARCH"
  info "  INSTANA_IS_S390X=$INSTANA_IS_S390X"
}

# Made with Bob
