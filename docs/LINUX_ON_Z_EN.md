# Instana Self-Hosted Custom Edition on Linux on Z (s390x)

This guide provides specific information for installing and configuring Instana Self-Hosted Custom Edition on Linux on Z systems (s390x architecture).

## Table of Contents

1. [Overview](#overview)
2. [s390x-Specific Requirements](#s390x-specific-requirements)
3. [Prerequisites](#prerequisites)
4. [Architecture Considerations](#architecture-considerations)
5. [Installation](#installation)
6. [s390x-Specific Configuration](#s390x-specific-configuration)
7. [Installation Verification](#installation-verification)
8. [Troubleshooting](#troubleshooting)
9. [Known Limitations](#known-limitations)
10. [Best Practices](#best-practices)

## Overview

Instana Self-Hosted Custom Edition supports the s390x architecture (Linux on Z), enabling you to run the observability platform on IBM Z mainframes. This guide covers specific considerations and steps necessary for a successful installation.

## s390x-Specific Requirements

### Minimum Hardware Requirements

| Component | Minimum Requirement | Recommended |
|------------|---------------------|--------------|
| CPU | 8 cores | 16+ cores |
| RAM Memory | 32 GB | 64+ GB |
| Storage | 500 GB | 1+ TB |
| Architecture | s390x | s390x |

### Software Requirements

- **Operating System**: 
  - Red Hat Enterprise Linux (RHEL) 8.x or 9.x for s390x
  - SUSE Linux Enterprise Server (SLES) 15 SP3+ for s390x
  - Ubuntu 20.04 LTS or 22.04 LTS for s390x

- **Kubernetes**:
  - Version 1.25 or higher
  - OpenShift Container Platform 4.13+ (recommended for s390x)

- **Container Runtime**:
  - CRI-O (recommended for OpenShift)
  - containerd
  - Docker (deprecated but still supported)

## Prerequisites

### 1. Installing kubectl for s390x

```bash
# Download kubectl for s390x
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/s390x/kubectl"

# Make executable and move to PATH
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify installation
kubectl version --client=true
```

### 2. Installing Helm for s390x

```bash
# Download and install Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Verify installation
helm version
```

### 3. Installing yq for s390x

```bash
# For RHEL/CentOS
sudo yum install -y yq

# For Ubuntu/Debian
sudo snap install yq

# Verify installation
yq --version
```

### 4. Architecture Verification

```bash
# Verify system architecture
uname -m
# Expected output: s390x

# Verify Kubernetes node architecture
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.architecture}' | tr ' ' '\n' | sort -u
# Expected output: s390x
```

## Architecture Considerations

### Multi-Architecture Image Support

Instana provides multi-architecture container images that support:
- amd64 (x86_64)
- s390x (Linux on Z)
- arm64 (aarch64)
- ppc64le (Power)

Container images are automatically selected based on the Kubernetes node architecture.

### Image Registry

Ensure your container registry supports multi-architecture images:

```bash
# Verify multi-arch support for an image
docker manifest inspect artifact-public.instana.io/backend/instana-backend:latest
```

### Components with Limited Support

Some third-party components may have limited s390x support:
- Always verify s390x image availability
- Consult IBM documentation for s390x-specific alternatives

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/instana/self-hosted-custom-edition-setup.git
cd self-hosted-custom-edition-setup/deploy
```

### 2. Configure Environment Variables

Create the `config.env` file from the template:

```bash
cp config.env.template config.env
```

Edit `config.env` with your values:

```bash
# Instana Keys
SALES_KEY=your-sales-key
DOWNLOAD_KEY=your-download-key

# Cluster type (use 'ocp' for OpenShift on s390x)
CLUSTER_TYPE=ocp

# Unit and Tenant Configuration
INSTANA_UNIT_NAME=unit0
INSTANA_TENANT_NAME=tenant0

# Agent Key (optional)
AGENT_KEY=your-agent-key
```

### 3. Configure Custom Values

Create custom configuration files for specific components:

```bash
# Core configuration
cat > values/core/custom-values.yaml <<EOF
baseDomain: "instana.your-domain.com"

acceptors:
  agent:
    host: "agent.instana.your-domain.com"
    port: 443

# Storage configuration for s390x
storageConfigs:
  rawSpans:
    pvcConfig:
      accessModes:
        - ReadWriteMany
      resources:
        requests:
          storage: 500Gi
      storageClassName: "your-storage-class"

# Resource configuration optimized for s390x
imageConfig:
  tag: 3.xxx.xxx-x
EOF
```

### 4. Run the Installation

```bash
# Run pre-check (includes architecture validation)
./shce.sh apply
```

The script will automatically:
- Detect s390x architecture
- Validate Linux on Z specific requirements
- Verify cluster compatibility
- Install all components

## s390x-Specific Configuration

### Resource Optimization

For s390x systems, consider these optimizations:

#### Cassandra

```yaml
# values/cassandra/custom-values.yaml
size: 3
storage: 500Gi
resources:
  requests:
    cpu: "4000m"
    memory: "16Gi"  # Increased for s390x
  limits:
    memory: "16Gi"
jvmServerOptions:
  initialHeapSize: "6G"
  maxHeapSize: "12G"
```

#### Elasticsearch

```yaml
# values/elasticsearch/custom-values.yaml
nodeSets:
  - name: default
    count: 3
    resources:
      requests:
        cpu: "2000m"
        memory: "12Gi"  # Increased for s390x
      limits:
        memory: "12Gi"
    volume:
      resources:
        requests:
          storage: 500Gi
```

#### ClickHouse

```yaml
# values/clickhouse/custom-values.yaml
clickhouse:
  resources:
    requests:
      cpu: "8000m"  # Increased for s390x
      memory: "24Gi"
    limits:
      memory: "24Gi"
  volumeClaimTemplates:
    dataStorage: "1Ti"  # Increased for s390x
```

#### Kafka

```yaml
# values/kafka/custom-values.yaml
resources:
  kafka:
    requests:
      cpu: "6000m"  # Increased for s390x
      memory: "24Gi"
    limits:
      memory: "24Gi"
storage:
  size:
    kafka: 1Ti  # Increased for s390x
```

### Storage Class Configuration

For OpenShift on s390x, use appropriate storage classes:

```yaml
# Example for IBM Storage
storageClassName: "ibm-spectrum-scale-sc"

# Example for Ceph
storageClassName: "rook-ceph-block"

# Example for NFS
storageClassName: "nfs-client"
```

## Installation Verification

### 1. Verify Pod Architecture

```bash
# Verify pods are using s390x images
kubectl get pods -n instana-core -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'

# Verify node architecture where pods are running
kubectl get pods -n instana-core -o wide
```

### 2. Verify Component Status

```bash
# Verify all Instana namespaces
kubectl get pods -A | grep instana

# Verify datastore status
kubectl get pods -n instana-kafka
kubectl get pods -n instana-elastic
kubectl get pods -n instana-cassandra
kubectl get pods -n instana-clickhouse
kubectl get pods -n instana-postgres
kubectl get pods -n instana-beeinstana

# Verify backend status
kubectl get pods -n instana-core
kubectl get pods -n instana-units
```

### 3. Verify Custom Resources

```bash
# Verify Core
kubectl get core -n instana-core

# Verify Unit
kubectl get unit -n instana-units

# Verify detailed status
kubectl describe core instana-core -n instana-core
kubectl describe unit ${INSTANA_UNIT_NAME}-${INSTANA_TENANT_NAME} -n instana-units
```

### 4. Connectivity Testing

```bash
# Test UI
curl -k https://${BASE_DOMAIN}

# Test agent acceptor
curl -k https://${AGENT_ACCEPTOR}
```

## Troubleshooting

### Issue: Images Not Available for s390x

**Symptom**: Pods in `ImagePullBackOff` or `ErrImagePull` state

**Solution**:
```bash
# Verify image availability for s390x
docker manifest inspect <image-name>:<tag>

# If image doesn't support s390x, contact IBM support
# or look for a compatible alternative
```

### Issue: Degraded Performance

**Symptom**: General system slowness

**Solution**:
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n instana-core

# Increase resources in custom-values.yaml files
# Reapply configuration
./shce.sh backend apply
```

### Issue: Storage Class Not Found

**Symptom**: PVC in `Pending` state

**Solution**:
```bash
# List available storage classes
kubectl get storageclass

# Set a default storage class
kubectl patch storageclass <storage-class-name> \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Verify
kubectl get storageclass
```

### Issue: Mixed Architecture Nodes

**Symptom**: Some pods don't start on s390x nodes

**Solution**:
```bash
# Add node selector to deployments
kubectl patch deployment <deployment-name> -n <namespace> \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/arch":"s390x"}}}}}'

# Or use node affinity in custom-values.yaml
```

### Logs and Diagnostics

```bash
# Pre-check logs
./shce.sh apply 2>&1 | tee installation.log

# Pod logs
kubectl logs -n instana-core <pod-name>

# Cluster events
kubectl get events -n instana-core --sort-by='.lastTimestamp'

# Detailed pod description
kubectl describe pod <pod-name> -n instana-core
```

## Known Limitations

1. **Third-Party Components**: Some components may have limited functionality on s390x
2. **Performance**: Performance may vary compared to x86_64 depending on workload
3. **Updates**: Always verify new version availability for s390x before upgrading
4. **Browser Tools**: Some development tools may not be available for s390x

## Best Practices

### 1. Capacity Planning

- Over-provision resources by 20-30% above minimum requirements
- Monitor resource usage regularly
- Plan for storage growth

### 2. High Availability

```yaml
# Distribute pods across multiple nodes
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - instana
        topologyKey: kubernetes.io/hostname
```

### 3. Backup and Disaster Recovery

```bash
# Backup configurations
kubectl get core,unit -A -o yaml > instana-backup.yaml

# Backup datastores (example for Cassandra)
kubectl exec -n instana-cassandra cassandra-0 -- nodetool snapshot
```

### 4. Monitoring

- Configure Instana internal monitoring
- Monitor s390x-specific metrics
- Set up alerts for resource usage

### 5. Security

```yaml
# Use appropriate security contexts
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
```

### 6. Updates

```bash
# Before updating, verify s390x compatibility
# Test in non-production environment
# Perform complete backup
# Follow documented upgrade procedure
```

## Additional Resources

- [IBM Instana Documentation](https://www.ibm.com/docs/en/instana-observability/current)
- [IBM Z Documentation](https://www.ibm.com/docs/en/linux-on-systems?topic=linux-z)
- [OpenShift on IBM Z](https://docs.openshift.com/container-platform/latest/installing/installing_ibm_z/preparing-to-install-on-ibm-z.html)
- [Kubernetes on s390x](https://kubernetes.io/docs/setup/production-environment/tools/)

## Support

For s390x-specific assistance:
- Contact IBM support
- Consult the Instana community
- Check installation logs in `installation.log`

---

**Note**: This guide is specific to s390x architecture. For other architectures, refer to the main documentation in [`README.md`](../README.md:1).