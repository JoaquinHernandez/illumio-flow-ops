# illumio-flow-ops
# ⚡ illumio-flow-ops

> Enterprise-grade Bash automation for Illumio Core PCE: VEN health validation, CMDB label ingestion, asynchronous traffic flow exploration, and automated zero trust policy lifecycle gating.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Language-Bash%204%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Illumio API](https://img.shields.io/badge/Illumio%20PCE-v2%20API-orange.svg)](https://docs.illumio.com)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

---

## 🎯 Overview

Deploying microsegmentation across hundreds or thousands of heterogeneous workloads requires strict operational rigor. `illumio-flow-ops` bridges the gap between raw PCE APIs and enterprise ITSM systems:

- **VEN Health & Compatibility Gates:** Interrogates VEN runtime states and validates host OS kernel/packet filtering compatibility prior to enforcement shifts.
- **Bi-directional CMDB Ingestion:** Queries ServiceNow (`cmdb_ci_server`) table records to normalize and map Role, Application, Environment, and Location labels.
- **Flow Explorer Telemetry:** Automates PCE async query jobs to extract raw flow metrics, detecting blocked/potentially blocked paths.
- **Stage-Gated Promotion Engine:** Automates safe lifecycle movement (`idle` ➔ `visibility_only` ➔ `selective`) with dry-run fail-safes.

---

## 🏗️ Architecture

```text
illumio-flow-ops/
├── bin/
│   └── illumio-ops.sh         # Unified CLI controller
├── lib/
│   ├── api.sh                 # REST client, basic auth & rate-limit handling
│   ├── workloads.sh           # Workload inventory, VEN health & compat audits
│   ├── traffic.sh             # Explorer async flow query generation & parsing
│   ├── policies.sh            # Ruleset resolution & AppID policy lookups
│   ├── snow.sh                # ServiceNow CMDB ingestion & label reconciliation
│   └── lifecycle.sh           # Stage-gated enforcement engine (Idle -> VO -> Selective)
├── config/
│   └── illumio.conf.example   # Configuration template
├── logs/                      # Audit trails & async flow payload dumps
└── README.md


PrerequisitesEnsure your orchestrator or operations workstation has the following installed:Bash 4.2+curl (7.68+ with OpenSSL support)jq (v1.6+)gzip / gunzip🚀 Quickstart1. Clone & ConfigureBashgit clone [https://github.com/your-org/illumio-flow-ops.git](https://github.com/your-org/illumio-flow-ops.git)
cd illumio-flow-ops

# Set up local configuration
cp config/illumio.conf.example config/illumio.conf
chmod 600 config/illumio.conf
2. Update config/illumio.confBash# PCE Connection Details
PCE_FQDN="pce.internal.network"
PCE_PORT="8443"
PCE_ORG_ID="1"
PCE_API_KEY="api_xxxxxxxxxxxxxxxx"
PCE_API_SECRET="sec_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# ServiceNow / CMDB Settings
SNOW_INSTANCE="corp.service-now.com"
SNOW_USER="svc_illumio_cmdb"
SNOW_PASS="VaultedSecurePassword123"

# Safety Defaults
DRY_RUN="true"                 # Set to 'false' to commit policy & mode changes
LOG_DIR="./logs"
3. Grant Execution PermissionsBashchmod +x bin/illumio-ops.sh
🛠️ UsageAll actions execute through the unified bin/illumio-ops.sh entrypoint.Audit VEN Agent Health & CompatibilityScan all paired workloads, report connectivity, agent state, and compatibility qualification:Bash./bin/illumio-ops.sh ven-audit
Extract Workload Traffic TelemetryAsynchronously poll the PCE Explorer API for historical flow records (blocked, potentially blocked, allowed) over the trailing 7 days:Bash./bin/illumio-ops.sh traffic app-db-prod-01.internal
Reconcile ServiceNow CMDB MetadataPull assigned application tags, environments, and business services from ServiceNow and align them with PCE label definitions:Bash./bin/illumio-ops.sh sync-cmdb web-tier-prod-04.internal
Execute Enforcement Lifecycle TransitionsEvaluate nodes against qualification gates and promote safely:Bash# Test execution with dry-run protection
./bin/illumio-ops.sh promote

# Live promotion (requires DRY_RUN="false" in illumio.conf)
./bin/illumio-ops.sh promote
🛡️ Promotion Lifecycle Guardrails[ Unpaired Server ]
        │
        ▼
   [ VEN Idle ]  ──────( Compatibility Check: FAIL )──────►  [ Hold & Alert ]
        │
        │ Compatibility Check: PASS
        ▼
[ Visibility-Only ]  ───( Unmodeled Flow Check: PENDING )──►  [ Flow Modeling ]
        │
        │ Rules Modeled & Zero Blockers
        ▼
[ Selective / Full Enforcement ]
Idle $\to$ Visibility-Only: Evaluates /workloads/{href}/compatibility_report. If raw iptables/WFP conflicts or driver discrepancies flag fail or yellow, the transition aborts.Visibility-Only $\to$ Selective: Validates that traffic collection has run for the designated quiet period and models baseline application policies before ring-fencing.🤝 ContributingFork the ProjectCreate your Feature Branch (git checkout -b feature/dynamic-ruleset-builder)Commit your Changes (git commit -m 'feat: add automated policy builder from async flows')Push to the Branch (git push origin feature/dynamic-ruleset-builder)Open a Pull Request📄 LicenseDistributed under the MIT License. See LICENSE for more information.
