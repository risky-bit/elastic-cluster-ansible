# Deployment Plan

Three phases: learn on laptop, set up automation host, deploy to production. No phase is skipped.

---

## Phase A — Learn Ansible (Laptop)

**Goal:** Build enough Ansible mental model to read, understand, and safely modify the inherited playbooks before touching any real infrastructure.

| Step | Action | Output |
|---|---|---|
| A1 | Bootstrap repo scaffold | This file, `.gitignore`, `README.md`, folder structure |
| A2 | Install Ansible on laptop; run hello-world ping against localhost | `learning/01-hello-world/` |
| A3 | Read consultant bundle playbooks together; understand task/handler/template structure | Notes in `learning/02-prepare-hosts-walkthrough/` |
| A4 | Annotated walkthrough of the `prepare-hosts` playbook | `learning/02-prepare-hosts-walkthrough/` |
| A5 | Understand inventory files, group_vars, and variable precedence | Learning notes |
| A6 | Understand ansible-vault: encrypt, edit, decrypt a dummy secret | Learning notes |
| A7 | Understand Jinja2 templates used in ES and Kibana config generation | Learning notes |

---

## Phase B — Set Up Automation Host

**Goal:** Replicate the working Ansible environment on the dedicated automation host, with production secrets vaulted and SSH access to all cluster nodes confirmed.

| Step | Action | Output |
|---|---|---|
| B1 | Install Ansible and dependencies on automation host (offline RPM) | Ansible available on host |
| B2 | Copy Ansible files to automation host (manual transfer — no git) | Working files on host |
| B3 | Distribute SSH keys from automation host to all cluster nodes | Passwordless SSH confirmed |
| B4 | Configure `ansible/ansible.cfg` for the production inventory | `ansible/ansible.cfg` |
| B5 | Populate `ansible/inventory/prod.ini` (gitignored) with real IPs and hostnames | Gitignored inventory file |
| B6 | Vault all secrets into `group_vars/all/vault.yml` | Gitignored vault file |
| B7 | Confirm Ansible ad-hoc ping reaches all nodes: `ansible all -m ping` | All green |
| B8 | Stage RPMs on automation host; verify SHA256 against `binaries/README.md` | Verified binaries |

---

## Phase C — Dev Validation → Production Deploy

**Goal:** Validate every playbook against dev VMs before executing against production. Promote only after each dev gate passes.

| Step | Action | Output |
|---|---|---|
| C1 | Run `prepare-hosts` on dev VMs; validate OS settings (ulimits, vm.max_map_count, heap) | Dev hosts prepared |
| C2 | Deploy Elasticsearch to dev cluster (3-node co-located, consultant bundle baseline) | Running dev ES cluster |
| C3 | Validate dev cluster health (`GET /_cluster/health`) | Green status |
| C4 | Deploy Kibana and Metricbeat to dev | Working dev UI |
| C5 | Adapt playbooks for production split-role design (separate master vs data inventories) | Updated playbooks |
| C6 | Write missing playbooks: Logstash, Fleet Server, NGINX | New playbooks |
| C7 | Write monitoring cluster playbooks (2-node + voting-only node) | Monitoring stack |
| C8 | Production deploy — phased order: masters → data/ingest nodes → Logstash/Kibana/Fleet → monitoring cluster + NGINX | Production cluster up |
| C9 | Post-deploy: apply ILM/SLM policies, register NFS snapshot repo | Data management in place |
| C10 | Set up Semaphore UI on automation host for scheduled re-runs | Semaphore running |

---

## Open decisions

- **Automation host placement:** Keep dedicated (recommended) vs fold into a monitoring node post-deploy. See `docs/decisions/` if this is revisited.
- **Secrets workflow:** ansible-vault is the destination. Introduced in Phase C, not earlier.
