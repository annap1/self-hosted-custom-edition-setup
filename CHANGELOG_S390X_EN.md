# Changelog - Linux on Z (s390x) Support

This document describes the modifications made to the project to support the s390x architecture (Linux on Z).

## Date: 2026-06-05

### New Files Created

#### 1. `deploy/arch-helper.sh`
Helper script for system architecture detection and validation.

**Main Features:**
- `detect_architecture()` - Detects system architecture (x86_64, s390x, arm64, ppc64le)
- `validate_architecture()` - Validates that the architecture is supported
- `is_linux_on_z()` - Checks if the system is Linux on Z (s390x)
- `get_kubectl_download_url()` - Provides the correct URL to download kubectl for the specific architecture
- `validate_kubectl_architecture()` - Verifies that kubectl is compiled for the correct architecture
- `check_s390x_requirements()` - Performs s390x-specific checks (memory, CPU, kernel modules)
- `validate_cluster_architecture()` - Verifies that Kubernetes cluster nodes support the required architecture
- `print_arch_notes()` - Prints architecture-specific notes during installation
- `export_arch_info()` - Exports environment variables with architecture information

#### 2. `docs/LINUX_ON_Z_EN.md`
Complete and detailed documentation for installation on Linux on Z (English version).

**Contents:**
- Overview of s390x support
- Specific hardware and software requirements
- Detailed prerequisites (kubectl, helm, yq for s390x)
- Step-by-step installation guide
- Optimized configurations for s390x
- Configuration examples for all datastores
- Troubleshooting guide
- Best practices for s390x deployment
- Known limitations
- Additional resources

#### 3. `docs/LINUX_ON_Z.md`
Complete and detailed documentation for installation on Linux on Z (Italian version).

**Contents:**
- Same as English version but in Italian language

#### 4. `deploy/values/core/instana-values-s390x.yaml`
Example configuration file optimized for s390x architecture.

**Features:**
- Resource configurations optimized for s390x
- Node selector for s390x nodes
- Affinity rules for high availability
- Recommended storage configurations
- Feature flags enabled by default

#### 5. `deploy/validate-s390x.sh`
Pre-installation validation script specific for s390x systems.

**Checks Performed:**
- Verify system architecture (must be s390x)
- Check operating system and version
- Verify memory (minimum 32GB, recommended 64GB+)
- Check CPU (minimum 8 cores, recommended 16+)
- Verify disk space
- Check kubectl (installation and architecture)
- Check Helm
- Check yq
- Verify Kubernetes version (>= 1.25)
- Check cluster nodes and architectures
- Verify storage class
- Check required kernel modules
- Verify container runtime

### Modified Files

#### 1. `deploy/shce.sh`
**Modifications:**
- Added source of `arch-helper.sh` at the beginning of the script
- Integrated architecture validation in the `precheck()` function
- Added calls to:
  - `validate_architecture()` - Validates supported architecture
  - `export_arch_info()` - Exports architecture environment variables
  - `validate_kubectl_architecture()` - Verifies kubectl
  - `check_s390x_requirements()` - s390x-specific checks
  - `validate_cluster_architecture()` - Verifies cluster nodes
  - `print_arch_notes()` - Prints architecture notes

**Modified Lines:**
- Line 1-8: Added source of arch-helper.sh
- Line 47-58: Updated precheck() function with architecture validations
- Line 360-377: Added source of arch-helper.sh in main()

#### 2. `deploy/datastores.sh`
**Modifications:**
- Added initial comment about multi-architecture support
- Added informative logs for s390x installations in all datastore installation functions:
  - `install_datastore_cassandra()`
  - `install_datastore_clickhouse()`
  - `install_datastore_es()`
  - `install_datastore_kafka()`
  - `install_datastore_postgres()`

**Modified Lines:**
- Line 1-5: Added comment about multi-arch support
- Line 41-51: Added log for Cassandra on s390x
- Line 71-78: Added log for ClickHouse on s390x
- Line 90-97: Added log for Elasticsearch on s390x
- Line 112-119: Added log for Kafka on s390x
- Line 137-145: Added log for PostgreSQL on s390x

#### 3. `README.md`
**Modifications:**
- Added "Architecture Support" section at the beginning of the document
- Updated prerequisites section with instructions for s390x
- Updated file structure to include arch-helper.sh and documentation
- Added architecture-specific troubleshooting section
- Added references to Linux on Z documentation

**Added/Modified Sections:**
- Line 5-12: New "Architecture Support" section
- Line 87-92: Updated kubectl installation instructions with s390x example
- Line 140-147: Updated file structure with arch-helper.sh
- Line 185-188: Added reference to docs/LINUX_ON_Z_EN.md
- Line 836-854: Updated troubleshooting section with architecture info

### Exported Environment Variables

The scripts now export the following environment variables:

- `INSTANA_ARCH` - Normalized architecture (amd64, s390x, arm64, ppc64le)
- `INSTANA_SYSTEM_ARCH` - Raw system architecture (output of uname -m)
- `INSTANA_IS_S390X` - Boolean (true/false) indicating if the system is s390x

### Compatibility

All modifications are backward compatible:
- Scripts work on all supported architectures (x86_64, s390x, arm64, ppc64le)
- Architecture detection is automatic
- No changes required to existing configuration files
- Container images are multi-architecture and automatically selected

### How to Use the New Features

#### For Standard Installation on s390x:
```bash
cd deploy
cp config.env.template config.env
# Edit config.env with your values
./shce.sh apply
```

#### For Pre-Installation Validation on s390x:
```bash
cd deploy
./validate-s390x.sh
```

#### To Use Optimized s390x Configurations:
```bash
cd deploy/values/core
cp instana-values-s390x.yaml custom-values.yaml
# Edit custom-values.yaml as needed
cd ../..
./shce.sh apply
```

### Important Notes

1. **Multi-Arch Images**: All Instana images support multi-architecture. The system automatically selects the correct variant.

2. **Hardware Requirements**: s390x systems require more resources than x86_64 for optimal performance.

3. **OpenShift Recommended**: For s390x deployments, OpenShift Container Platform 4.13+ is recommended.

4. **Storage**: Ensure the storage class supports ReadWriteMany (RWX) for some components.

5. **Automatic Validation**: The main script now automatically performs architecture validation during precheck.

### Testing

The modifications have been tested for:
- ✅ Correct architecture detection
- ✅ Prerequisites validation
- ✅ Compatibility with existing scripts
- ✅ Functionality on multiple architectures

### Next Steps

To use these modifications on a Linux on Z system:

1. Clone the repository
2. Read the documentation in `docs/LINUX_ON_Z_EN.md` (or `docs/LINUX_ON_Z.md` for Italian)
3. Run `deploy/validate-s390x.sh` to validate the system
4. Configure `deploy/config.env`
5. Optionally, use `deploy/values/core/instana-values-s390x.yaml` as a base
6. Run `deploy/shce.sh apply`

### Support

For s390x-specific issues:
- Consult `docs/LINUX_ON_Z_EN.md` or `docs/LINUX_ON_Z.md`
- Check installation logs
- Run `validate-s390x.sh` for diagnostics
- Contact IBM support

### Author

Modifications implemented to support Linux on Z (s390x) - 2026-06-05

### License

(c) Copyright IBM Corp. 2025