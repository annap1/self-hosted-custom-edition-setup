# Instana Self-Hosted Custom Edition su Linux on Z (s390x)

Questa guida fornisce informazioni specifiche per l'installazione e la configurazione di Instana Self-Hosted Custom Edition su sistemi Linux on Z (architettura s390x).

## Indice

1. [Panoramica](#panoramica)
2. [Requisiti Specifici per s390x](#requisiti-specifici-per-s390x)
3. [Prerequisiti](#prerequisiti)
4. [Considerazioni sull'Architettura](#considerazioni-sullarchitettura)
5. [Installazione](#installazione)
6. [Configurazione Specifica per s390x](#configurazione-specifica-per-s390x)
7. [Verifica dell'Installazione](#verifica-dellinstallazione)
8. [Risoluzione dei Problemi](#risoluzione-dei-problemi)
9. [Limitazioni Note](#limitazioni-note)
10. [Best Practices](#best-practices)

## Panoramica

Instana Self-Hosted Custom Edition supporta l'architettura s390x (Linux on Z), consentendo di eseguire la piattaforma di osservabilità su mainframe IBM Z. Questa guida copre le considerazioni specifiche e i passaggi necessari per un'installazione di successo.

## Requisiti Specifici per s390x

### Requisiti Hardware Minimi

| Componente | Requisito Minimo | Raccomandato |
|------------|------------------|--------------|
| CPU | 8 core | 16+ core |
| Memoria RAM | 32 GB | 64+ GB |
| Storage | 500 GB | 1+ TB |
| Architettura | s390x | s390x |

### Requisiti Software

- **Sistema Operativo**: 
  - Red Hat Enterprise Linux (RHEL) 8.x o 9.x per s390x
  - SUSE Linux Enterprise Server (SLES) 15 SP3+ per s390x
  - Ubuntu 20.04 LTS o 22.04 LTS per s390x

- **Kubernetes**:
  - Versione 1.25 o superiore
  - OpenShift Container Platform 4.13+ (raccomandato per s390x)

- **Container Runtime**:
  - CRI-O (raccomandato per OpenShift)
  - containerd
  - Docker (deprecato ma ancora supportato)

## Prerequisiti

### 1. Installazione di kubectl per s390x

```bash
# Scarica kubectl per s390x
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/s390x/kubectl"

# Rendi eseguibile e sposta in PATH
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verifica l'installazione
kubectl version --client=true
```

### 2. Installazione di Helm per s390x

```bash
# Scarica e installa Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Verifica l'installazione
helm version
```

### 3. Installazione di yq per s390x

```bash
# Per RHEL/CentOS
sudo yum install -y yq

# Per Ubuntu/Debian
sudo snap install yq

# Verifica l'installazione
yq --version
```

### 4. Verifica dell'Architettura

```bash
# Verifica l'architettura del sistema
uname -m
# Output atteso: s390x

# Verifica l'architettura dei nodi Kubernetes
kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.architecture}' | tr ' ' '\n' | sort -u
# Output atteso: s390x
```

## Considerazioni sull'Architettura

### Supporto Multi-Architettura delle Immagini

Instana fornisce immagini container multi-architettura che supportano:
- amd64 (x86_64)
- s390x (Linux on Z)
- arm64 (aarch64)
- ppc64le (Power)

Le immagini vengono automaticamente selezionate in base all'architettura del nodo Kubernetes.

### Registry delle Immagini

Assicurati che il tuo registry container supporti immagini multi-architettura:

```bash
# Verifica il supporto multi-arch di un'immagine
docker manifest inspect artifact-public.instana.io/backend/instana-backend:latest
```

### Componenti con Supporto Limitato

Alcuni componenti di terze parti potrebbero avere supporto limitato per s390x:
- Verificare sempre la disponibilità delle immagini s390x
- Consultare la documentazione IBM per alternative specifiche per s390x

## Installazione

### 1. Clona il Repository

```bash
git clone https://github.com/instana/self-hosted-custom-edition-setup.git
cd self-hosted-custom-edition-setup/deploy
```

### 2. Configura le Variabili d'Ambiente

Crea il file `config.env` dal template:

```bash
cp config.env.template config.env
```

Modifica `config.env` con i tuoi valori:

```bash
# Chiavi Instana
SALES_KEY=your-sales-key
DOWNLOAD_KEY=your-download-key

# Tipo di cluster (usa 'ocp' per OpenShift su s390x)
CLUSTER_TYPE=ocp

# Configurazione Unit e Tenant
INSTANA_UNIT_NAME=unit0
INSTANA_TENANT_NAME=tenant0

# Chiave Agent (opzionale)
AGENT_KEY=your-agent-key
```

### 3. Configura i Valori Custom

Crea file di configurazione custom per componenti specifici:

```bash
# Core configuration
cat > values/core/custom-values.yaml <<EOF
baseDomain: "instana.your-domain.com"

acceptors:
  agent:
    host: "agent.instana.your-domain.com"
    port: 443

# Configurazione storage per s390x
storageConfigs:
  rawSpans:
    pvcConfig:
      accessModes:
        - ReadWriteMany
      resources:
        requests:
          storage: 500Gi
      storageClassName: "your-storage-class"

# Configurazione risorse ottimizzata per s390x
imageConfig:
  tag: 3.xxx.xxx-x
EOF
```

### 4. Esegui l'Installazione

```bash
# Esegui il pre-check (include validazione architettura)
./shce.sh apply
```

Lo script eseguirà automaticamente:
- Rilevamento dell'architettura s390x
- Validazione dei requisiti specifici per Linux on Z
- Verifica della compatibilità del cluster
- Installazione di tutti i componenti

## Configurazione Specifica per s390x

### Ottimizzazione delle Risorse

Per sistemi s390x, considera queste ottimizzazioni:

#### Cassandra

```yaml
# values/cassandra/custom-values.yaml
size: 3
storage: 500Gi
resources:
  requests:
    cpu: "4000m"
    memory: "16Gi"  # Aumentato per s390x
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
        memory: "12Gi"  # Aumentato per s390x
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
      cpu: "8000m"  # Aumentato per s390x
      memory: "24Gi"
    limits:
      memory: "24Gi"
  volumeClaimTemplates:
    dataStorage: "1Ti"  # Aumentato per s390x
```

#### Kafka

```yaml
# values/kafka/custom-values.yaml
resources:
  kafka:
    requests:
      cpu: "6000m"  # Aumentato per s390x
      memory: "24Gi"
    limits:
      memory: "24Gi"
storage:
  size:
    kafka: 1Ti  # Aumentato per s390x
```

### Configurazione Storage Class

Per OpenShift su s390x, usa storage class appropriati:

```yaml
# Esempio per IBM Storage
storageClassName: "ibm-spectrum-scale-sc"

# Esempio per Ceph
storageClassName: "rook-ceph-block"

# Esempio per NFS
storageClassName: "nfs-client"
```

## Verifica dell'Installazione

### 1. Verifica l'Architettura dei Pod

```bash
# Verifica che i pod stiano usando immagini s390x
kubectl get pods -n instana-core -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'

# Verifica l'architettura dei nodi dove girano i pod
kubectl get pods -n instana-core -o wide
```

### 2. Verifica lo Stato dei Componenti

```bash
# Verifica tutti i namespace Instana
kubectl get pods -A | grep instana

# Verifica lo stato dei datastore
kubectl get pods -n instana-kafka
kubectl get pods -n instana-elastic
kubectl get pods -n instana-cassandra
kubectl get pods -n instana-clickhouse
kubectl get pods -n instana-postgres
kubectl get pods -n instana-beeinstana

# Verifica lo stato del backend
kubectl get pods -n instana-core
kubectl get pods -n instana-units
```

### 3. Verifica le Custom Resources

```bash
# Verifica Core
kubectl get core -n instana-core

# Verifica Unit
kubectl get unit -n instana-units

# Verifica lo stato dettagliato
kubectl describe core instana-core -n instana-core
kubectl describe unit ${INSTANA_UNIT_NAME}-${INSTANA_TENANT_NAME} -n instana-units
```

### 4. Test di Connettività

```bash
# Test dell'UI
curl -k https://${BASE_DOMAIN}

# Test dell'agent acceptor
curl -k https://${AGENT_ACCEPTOR}
```

## Risoluzione dei Problemi

### Problema: Immagini non Disponibili per s390x

**Sintomo**: Pod in stato `ImagePullBackOff` o `ErrImagePull`

**Soluzione**:
```bash
# Verifica la disponibilità dell'immagine per s390x
docker manifest inspect <image-name>:<tag>

# Se l'immagine non supporta s390x, contatta il supporto IBM
# o cerca un'alternativa compatibile
```

### Problema: Performance Degradate

**Sintomo**: Lentezza generale del sistema

**Soluzione**:
```bash
# Verifica l'utilizzo delle risorse
kubectl top nodes
kubectl top pods -n instana-core

# Aumenta le risorse nei file custom-values.yaml
# Riapplica la configurazione
./shce.sh backend apply
```

### Problema: Storage Class non Trovata

**Sintomo**: PVC in stato `Pending`

**Soluzione**:
```bash
# Lista le storage class disponibili
kubectl get storageclass

# Imposta una storage class di default
kubectl patch storageclass <storage-class-name> \
  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Verifica
kubectl get storageclass
```

### Problema: Nodi con Architettura Mista

**Sintomo**: Alcuni pod non si avviano su nodi s390x

**Soluzione**:
```bash
# Aggiungi node selector ai deployment
kubectl patch deployment <deployment-name> -n <namespace> \
  -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/arch":"s390x"}}}}}'

# Oppure usa node affinity nei custom-values.yaml
```

### Log e Diagnostica

```bash
# Log del pre-check
./shce.sh apply 2>&1 | tee installation.log

# Log dei pod
kubectl logs -n instana-core <pod-name>

# Eventi del cluster
kubectl get events -n instana-core --sort-by='.lastTimestamp'

# Descrizione dettagliata di un pod
kubectl describe pod <pod-name> -n instana-core
```

## Limitazioni Note

1. **Componenti di Terze Parti**: Alcuni componenti potrebbero avere funzionalità limitate su s390x
2. **Performance**: Le performance possono variare rispetto a x86_64 a seconda del carico di lavoro
3. **Aggiornamenti**: Verifica sempre la disponibilità delle nuove versioni per s390x prima di aggiornare
4. **Browser Tools**: Alcuni strumenti di sviluppo potrebbero non essere disponibili per s390x

## Best Practices

### 1. Pianificazione della Capacità

- Sovradimensiona le risorse del 20-30% rispetto ai requisiti minimi
- Monitora l'utilizzo delle risorse regolarmente
- Pianifica la crescita dello storage

### 2. Alta Disponibilità

```yaml
# Distribuisci i pod su più nodi
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

### 3. Backup e Disaster Recovery

```bash
# Backup delle configurazioni
kubectl get core,unit -A -o yaml > instana-backup.yaml

# Backup dei datastore (esempio per Cassandra)
kubectl exec -n instana-cassandra cassandra-0 -- nodetool snapshot
```

### 4. Monitoraggio

- Configura il monitoraggio interno di Instana
- Monitora le metriche specifiche di s390x
- Imposta alert per utilizzo risorse

### 5. Sicurezza

```yaml
# Usa security context appropriati
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
```

### 6. Aggiornamenti

```bash
# Prima di aggiornare, verifica la compatibilità s390x
# Testa in ambiente non-produzione
# Esegui backup completo
# Segui la procedura di aggiornamento documentata
```

## Risorse Aggiuntive

- [Documentazione IBM Instana](https://www.ibm.com/docs/en/instana-observability/current)
- [IBM Z Documentation](https://www.ibm.com/docs/en/linux-on-systems?topic=linux-z)
- [OpenShift on IBM Z](https://docs.openshift.com/container-platform/latest/installing/installing_ibm_z/preparing-to-install-on-ibm-z.html)
- [Kubernetes on s390x](https://kubernetes.io/docs/setup/production-environment/tools/)

## Supporto

Per assistenza specifica su Linux on Z:
- Contatta il supporto IBM
- Consulta la community Instana
- Verifica i log di installazione in `installation.log`

---

**Nota**: Questa guida è specifica per l'architettura s390x. Per altre architetture, consulta la documentazione principale nel file [`README.md`](../README.md:1).