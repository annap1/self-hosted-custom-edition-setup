#!/usr/bin/env bash
# (c) Copyright IBM Corp. 2025
# Pre-installation validation script for Linux on Z (s390x)

set -o errexit

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

info() {
  echo -e "${GREEN}[INFO]${NC} $*"
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
  ((WARNINGS++))
}

error() {
  echo -e "${RED}[ERROR]${NC} $*"
  ((FAILED++))
}

success() {
  echo -e "${GREEN}[PASS]${NC} $*"
  ((PASSED++))
}

check_architecture() {
  echo ""
  echo "=========================================="
  echo "Checking System Architecture"
  echo "=========================================="
  
  local arch=$(uname -m)
  if [[ "$arch" == "s390x" ]]; then
    success "System architecture is s390x"
  else
    error "System architecture is $arch, expected s390x"
    error "This validation script is for Linux on Z (s390x) systems only"
    return 1
  fi
}

check_os() {
  echo ""
  echo "=========================================="
  echo "Checking Operating System"
  echo "=========================================="
  
  if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    info "OS: $NAME $VERSION"
    
    case "$ID" in
      rhel|centos)
        if [[ "${VERSION_ID%%.*}" -ge 8 ]]; then
          success "RHEL/CentOS version is compatible"
        else
          warn "RHEL/CentOS version should be 8.x or higher"
        fi
        ;;
      sles)
        if [[ "${VERSION_ID%%.*}" -ge 15 ]]; then
          success "SLES version is compatible"
        else
          warn "SLES version should be 15 or higher"
        fi
        ;;
      ubuntu)
        if [[ "${VERSION_ID%%.*}" -ge 20 ]]; then
          success "Ubuntu version is compatible"
        else
          warn "Ubuntu version should be 20.04 or higher"
        fi
        ;;
      *)
        warn "Operating system $NAME is not officially tested for Instana on s390x"
        ;;
    esac
  else
    warn "Cannot determine operating system version"
  fi
}

check_memory() {
  echo ""
  echo "=========================================="
  echo "Checking System Memory"
  echo "=========================================="
  
  local total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  local total_mem_gb=$((total_mem_kb / 1024 / 1024))
  
  info "Total system memory: ${total_mem_gb}GB"
  
  if [[ $total_mem_gb -ge 64 ]]; then
    success "Memory is sufficient (${total_mem_gb}GB >= 64GB recommended)"
  elif [[ $total_mem_gb -ge 32 ]]; then
    warn "Memory is at minimum (${total_mem_gb}GB). 64GB+ recommended for production"
  else
    error "Insufficient memory (${total_mem_gb}GB < 32GB minimum)"
  fi
}

check_cpu() {
  echo ""
  echo "=========================================="
  echo "Checking CPU Cores"
  echo "=========================================="
  
  local cpu_count=$(grep -c ^processor /proc/cpuinfo)
  info "CPU cores: $cpu_count"
  
  if [[ $cpu_count -ge 16 ]]; then
    success "CPU cores are sufficient ($cpu_count >= 16 recommended)"
  elif [[ $cpu_count -ge 8 ]]; then
    warn "CPU cores are at minimum ($cpu_count). 16+ recommended for production"
  else
    error "Insufficient CPU cores ($cpu_count < 8 minimum)"
  fi
}

check_disk_space() {
  echo ""
  echo "=========================================="
  echo "Checking Disk Space"
  echo "=========================================="
  
  local root_space=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
  info "Available space on /: ${root_space}GB"
  
  if [[ $root_space -ge 100 ]]; then
    success "Disk space is sufficient (${root_space}GB >= 100GB)"
  else
    warn "Limited disk space (${root_space}GB). Ensure adequate storage for Kubernetes and containers"
  fi
}

check_kubectl() {
  echo ""
  echo "=========================================="
  echo "Checking kubectl"
  echo "=========================================="
  
  if command -v kubectl &> /dev/null; then
    local kubectl_version=$(kubectl version --client=true --output=json 2>/dev/null | grep -o '"gitVersion":"[^"]*"' | cut -d'"' -f4)
    info "kubectl version: $kubectl_version"
    
    # Check if kubectl is for s390x
    local kubectl_platform=$(kubectl version --client=true --output=json 2>/dev/null | grep -o '"platform":"[^"]*"' | cut -d'"' -f4)
    if [[ "$kubectl_platform" == *"s390x"* ]]; then
      success "kubectl is built for s390x architecture"
    else
      warn "kubectl platform: $kubectl_platform (expected s390x)"
    fi
    
    # Check if kubectl can connect to cluster
    if kubectl cluster-info &> /dev/null; then
      success "kubectl can connect to Kubernetes cluster"
    else
      error "kubectl cannot connect to Kubernetes cluster"
    fi
  else
    error "kubectl is not installed"
  fi
}

check_helm() {
  echo ""
  echo "=========================================="
  echo "Checking Helm"
  echo "=========================================="
  
  if command -v helm &> /dev/null; then
    local helm_version=$(helm version --short 2>/dev/null)
    info "Helm version: $helm_version"
    success "Helm is installed"
  else
    error "Helm is not installed"
  fi
}

check_yq() {
  echo ""
  echo "=========================================="
  echo "Checking yq"
  echo "=========================================="
  
  if command -v yq &> /dev/null; then
    local yq_version=$(yq --version 2>/dev/null)
    info "yq version: $yq_version"
    success "yq is installed"
  else
    error "yq is not installed"
  fi
}

check_kubernetes_version() {
  echo ""
  echo "=========================================="
  echo "Checking Kubernetes Version"
  echo "=========================================="
  
  if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null; then
    local k8s_version=$(kubectl version --output=json 2>/dev/null | grep -o '"gitVersion":"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/v//')
    local k8s_major=$(echo "$k8s_version" | cut -d. -f1)
    local k8s_minor=$(echo "$k8s_version" | cut -d. -f2)
    
    info "Kubernetes version: v$k8s_version"
    
    if [[ $k8s_major -eq 1 ]] && [[ $k8s_minor -ge 25 ]]; then
      success "Kubernetes version is compatible (>= 1.25)"
    else
      error "Kubernetes version must be 1.25 or higher"
    fi
  else
    warn "Cannot check Kubernetes version (cluster not accessible)"
  fi
}

check_cluster_nodes() {
  echo ""
  echo "=========================================="
  echo "Checking Cluster Nodes"
  echo "=========================================="
  
  if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null; then
    local node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    info "Number of nodes: $node_count"
    
    if [[ $node_count -ge 3 ]]; then
      success "Cluster has sufficient nodes ($node_count >= 3)"
    else
      warn "Cluster has limited nodes ($node_count). 3+ recommended for production"
    fi
    
    # Check node architectures
    local node_archs=$(kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.architecture}' 2>/dev/null | tr ' ' '\n' | sort -u)
    info "Node architectures: $(echo "$node_archs" | tr '\n' ' ')"
    
    if echo "$node_archs" | grep -q "s390x"; then
      success "Cluster has s390x nodes"
    else
      error "Cluster has no s390x nodes"
    fi
    
    # Check for mixed architectures
    local arch_count=$(echo "$node_archs" | wc -l)
    if [[ $arch_count -gt 1 ]]; then
      warn "Cluster has mixed architectures. Ensure proper node selectors are configured"
    fi
  else
    warn "Cannot check cluster nodes (cluster not accessible)"
  fi
}

check_storage_class() {
  echo ""
  echo "=========================================="
  echo "Checking Storage Classes"
  echo "=========================================="
  
  if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null; then
    local sc_count=$(kubectl get storageclass --no-headers 2>/dev/null | wc -l)
    
    if [[ $sc_count -gt 0 ]]; then
      info "Storage classes found: $sc_count"
      
      local default_sc=$(kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}' 2>/dev/null)
      
      if [[ -n "$default_sc" ]]; then
        success "Default storage class: $default_sc"
      else
        error "No default storage class configured"
      fi
      
      # List all storage classes
      info "Available storage classes:"
      kubectl get storageclass --no-headers 2>/dev/null | awk '{print "  - " $1}'
    else
      error "No storage classes found"
    fi
  else
    warn "Cannot check storage classes (cluster not accessible)"
  fi
}

check_kernel_modules() {
  echo ""
  echo "=========================================="
  echo "Checking Kernel Modules"
  echo "=========================================="
  
  local required_modules=("dm_mod" "overlay" "br_netfilter")
  
  for module in "${required_modules[@]}"; do
    if lsmod | grep -q "^$module"; then
      success "Kernel module $module is loaded"
    else
      warn "Kernel module $module is not loaded (may be required for some configurations)"
    fi
  done
}

check_container_runtime() {
  echo ""
  echo "=========================================="
  echo "Checking Container Runtime"
  echo "=========================================="
  
  if command -v kubectl &> /dev/null && kubectl cluster-info &> /dev/null; then
    local runtime=$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.containerRuntimeVersion}' 2>/dev/null)
    
    if [[ -n "$runtime" ]]; then
      info "Container runtime: $runtime"
      
      if [[ "$runtime" == *"cri-o"* ]] || [[ "$runtime" == *"containerd"* ]]; then
        success "Container runtime is compatible"
      elif [[ "$runtime" == *"docker"* ]]; then
        warn "Docker runtime is deprecated. Consider migrating to CRI-O or containerd"
      else
        warn "Unknown container runtime: $runtime"
      fi
    else
      warn "Cannot determine container runtime"
    fi
  else
    warn "Cannot check container runtime (cluster not accessible)"
  fi
}

print_summary() {
  echo ""
  echo "=========================================="
  echo "Validation Summary"
  echo "=========================================="
  echo -e "${GREEN}Passed:${NC} $PASSED"
  echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
  echo -e "${RED}Failed:${NC} $FAILED"
  echo ""
  
  if [[ $FAILED -eq 0 ]]; then
    if [[ $WARNINGS -eq 0 ]]; then
      echo -e "${GREEN}✓ All checks passed! System is ready for Instana installation.${NC}"
    else
      echo -e "${YELLOW}⚠ Some warnings detected. Review them before proceeding.${NC}"
    fi
    return 0
  else
    echo -e "${RED}✗ Some checks failed. Please address the errors before installation.${NC}"
    return 1
  fi
}

main() {
  echo "=========================================="
  echo "Instana s390x Pre-Installation Validation"
  echo "=========================================="
  echo ""
  
  check_architecture || exit 1
  check_os
  check_memory
  check_cpu
  check_disk_space
  check_kubectl
  check_helm
  check_yq
  check_kubernetes_version
  check_cluster_nodes
  check_storage_class
  check_kernel_modules
  check_container_runtime
  
  echo ""
  print_summary
}

main "$@"

# Made with Bob
