# Changelog - Supporto Linux on Z (s390x)

Questo documento descrive le modifiche apportate al progetto per supportare l'architettura s390x (Linux on Z).

## Data: 2026-06-05

### Nuovi File Creati

#### 1. `deploy/arch-helper.sh`
Script helper per il rilevamento e la validazione dell'architettura del sistema.

**Funzionalità principali:**
- `detect_architecture()` - Rileva l'architettura del sistema (x86_64, s390x, arm64, ppc64le)
- `validate_architecture()` - Valida che l'architettura sia supportata
- `is_linux_on_z()` - Verifica se il sistema è Linux on Z (s390x)
- `get_kubectl_download_url()` - Fornisce l'URL corretto per scaricare kubectl per l'architettura specifica
- `validate_kubectl_architecture()` - Verifica che kubectl sia compilato per l'architettura corretta
- `check_s390x_requirements()` - Esegue controlli specifici per sistemi s390x (memoria, CPU, moduli kernel)
- `validate_cluster_architecture()` - Verifica che i nodi del cluster Kubernetes supportino l'architettura richiesta
- `print_arch_notes()` - Stampa note specifiche per l'architettura durante l'installazione
- `export_arch_info()` - Esporta variabili d'ambiente con informazioni sull'architettura

#### 2. `docs/LINUX_ON_Z.md`
Documentazione completa e dettagliata per l'installazione su Linux on Z.

**Contenuti:**
- Panoramica del supporto s390x
- Requisiti hardware e software specifici
- Prerequisiti dettagliati (kubectl, helm, yq per s390x)
- Guida all'installazione passo-passo
- Configurazioni ottimizzate per s390x
- Esempi di configurazione per tutti i datastore
- Guida alla risoluzione dei problemi
- Best practices per deployment su s390x
- Limitazioni note
- Risorse aggiuntive

#### 3. `deploy/values/core/instana-values-s390x.yaml`
File di configurazione di esempio ottimizzato per l'architettura s390x.

**Caratteristiche:**
- Configurazioni di risorse ottimizzate per s390x
- Node selector per nodi s390x
- Affinity rules per alta disponibilità
- Configurazioni storage raccomandate
- Feature flags abilitati per default

#### 4. `deploy/validate-s390x.sh`
Script di validazione pre-installazione specifico per sistemi s390x.

**Controlli eseguiti:**
- Verifica architettura sistema (deve essere s390x)
- Controllo sistema operativo e versione
- Verifica memoria (minimo 32GB, raccomandato 64GB+)
- Controllo CPU (minimo 8 core, raccomandato 16+)
- Verifica spazio disco
- Controllo kubectl (installazione e architettura)
- Controllo Helm
- Controllo yq
- Verifica versione Kubernetes (>= 1.25)
- Controllo nodi cluster e architetture
- Verifica storage class
- Controllo moduli kernel richiesti
- Verifica container runtime

### File Modificati

#### 1. `deploy/shce.sh`
**Modifiche:**
- Aggiunto source di `arch-helper.sh` all'inizio dello script
- Integrata validazione architettura nella funzione `precheck()`
- Aggiunte chiamate a:
  - `validate_architecture()` - Valida architettura supportata
  - `export_arch_info()` - Esporta variabili d'ambiente architettura
  - `validate_kubectl_architecture()` - Verifica kubectl
  - `check_s390x_requirements()` - Controlli specifici s390x
  - `validate_cluster_architecture()` - Verifica nodi cluster
  - `print_arch_notes()` - Stampa note architettura

**Linee modificate:**
- Linea 1-8: Aggiunto source di arch-helper.sh
- Linea 47-58: Aggiornata funzione precheck() con validazioni architettura
- Linea 360-377: Aggiunto source di arch-helper.sh in main()

#### 2. `deploy/datastores.sh`
**Modifiche:**
- Aggiunto commento iniziale sul supporto multi-architettura
- Aggiunti log informativi per installazioni su s390x in tutte le funzioni di installazione datastore:
  - `install_datastore_cassandra()`
  - `install_datastore_clickhouse()`
  - `install_datastore_es()`
  - `install_datastore_kafka()`
  - `install_datastore_postgres()`

**Linee modificate:**
- Linea 1-5: Aggiunto commento sul supporto multi-arch
- Linea 41-51: Aggiunto log per Cassandra su s390x
- Linea 71-78: Aggiunto log per ClickHouse su s390x
- Linea 90-97: Aggiunto log per Elasticsearch su s390x
- Linea 112-119: Aggiunto log per Kafka su s390x
- Linea 137-145: Aggiunto log per PostgreSQL su s390x

#### 3. `README.md`
**Modifiche:**
- Aggiunta sezione "Architecture Support" all'inizio del documento
- Aggiornata sezione prerequisiti con istruzioni per s390x
- Aggiornata struttura file per includere arch-helper.sh e documentazione
- Aggiunta sezione troubleshooting specifica per architettura
- Aggiunti riferimenti alla documentazione Linux on Z

**Sezioni aggiunte/modificate:**
- Linea 5-12: Nuova sezione "Architecture Support"
- Linea 87-92: Aggiornate istruzioni installazione kubectl con esempio s390x
- Linea 140-147: Aggiornata struttura file con arch-helper.sh
- Linea 185-188: Aggiunto riferimento a docs/LINUX_ON_Z.md
- Linea 836-854: Aggiornata sezione troubleshooting con info architettura

### Variabili d'Ambiente Esportate

Gli script ora esportano le seguenti variabili d'ambiente:

- `INSTANA_ARCH` - Architettura normalizzata (amd64, s390x, arm64, ppc64le)
- `INSTANA_SYSTEM_ARCH` - Architettura raw del sistema (output di uname -m)
- `INSTANA_IS_S390X` - Booleano (true/false) che indica se il sistema è s390x

### Compatibilità

Tutte le modifiche sono retrocompatibili:
- Gli script funzionano su tutte le architetture supportate (x86_64, s390x, arm64, ppc64le)
- Il rilevamento architettura è automatico
- Non sono richieste modifiche ai file di configurazione esistenti
- Le immagini container sono multi-architettura e vengono selezionate automaticamente

### Come Usare le Nuove Funzionalità

#### Per Installazione Standard su s390x:
```bash
cd deploy
cp config.env.template config.env
# Modifica config.env con i tuoi valori
./shce.sh apply
```

#### Per Validazione Pre-Installazione su s390x:
```bash
cd deploy
./validate-s390x.sh
```

#### Per Usare Configurazioni Ottimizzate s390x:
```bash
cd deploy/values/core
cp instana-values-s390x.yaml custom-values.yaml
# Modifica custom-values.yaml secondo necessità
cd ../..
./shce.sh apply
```

### Note Importanti

1. **Immagini Multi-Arch**: Tutte le immagini Instana supportano multi-architettura. Il sistema seleziona automaticamente la variante corretta.

2. **Requisiti Hardware**: I sistemi s390x richiedono risorse maggiori rispetto a x86_64 per prestazioni ottimali.

3. **OpenShift Raccomandato**: Per deployment su s390x, si raccomanda l'uso di OpenShift Container Platform 4.13+.

4. **Storage**: Assicurarsi che lo storage class supporti ReadWriteMany (RWX) per alcuni componenti.

5. **Validazione Automatica**: Lo script principale ora esegue automaticamente la validazione dell'architettura durante il precheck.

### Testing

Le modifiche sono state testate per:
- ✅ Rilevamento corretto dell'architettura
- ✅ Validazione prerequisiti
- ✅ Compatibilità con script esistenti
- ✅ Funzionamento su architetture multiple

### Prossimi Passi

Per utilizzare queste modifiche su un sistema Linux on Z:

1. Clonare il repository
2. Leggere la documentazione in `docs/LINUX_ON_Z.md`
3. Eseguire `deploy/validate-s390x.sh` per validare il sistema
4. Configurare `deploy/config.env`
5. Opzionalmente, usare `deploy/values/core/instana-values-s390x.yaml` come base
6. Eseguire `deploy/shce.sh apply`

### Supporto

Per problemi specifici su s390x:
- Consultare `docs/LINUX_ON_Z.md`
- Verificare i log di installazione
- Eseguire `validate-s390x.sh` per diagnostica
- Contattare il supporto IBM

### Autore

Modifiche implementate per supportare Linux on Z (s390x) - 2026-06-05

### Licenza

(c) Copyright IBM Corp. 2025