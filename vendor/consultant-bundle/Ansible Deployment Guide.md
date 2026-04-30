# Ansible Deployment Guide

## 1. Project Layout

The project should follow a structure similar to the one below:

```./
 |- bin
 |   |- elasticsearch-9.2.4.rpm
 |   |- kibana-9.2.4.rpm
 |   |- metricbeat-9.2.4.rpm
 |- certs
 |   |- es.crt
 |   |- es.key
 |   |- kibana.crt
 |   |- kibana.key
 |   |- certfile.p12
 |- hosts.ini
 |- elastic9-playbook.yml
 |- elastic9-prepare-hosts.yml
 |- kibana9-playbook.yml
 |- metricbeat9-playbook.yml
 |- elasticsearch.yml.j2
 |- kibana.yml.j2
 |- metricbeat.yml.j2
 |- metricbeat-elasticsearch-xpack.yml.j2
 |- metricbeat-kibana-xpack.yml.j2
```

 ## 2. Key Components

### Inventory File (`.ini`)
The source of truth defining variables such as IP addresses, versions, paths, credentials, and host group structures.

### Playbooks (`.yml`)
Define the automation logic, specifying which tasks are executed on designated nodes.

### Templates (`.j2`)
Dynamic configuration files (e.g., `elasticsearch.yml`) leveraging Jinja2 templating to inject variables from the inventory.

### Binaries (`.rpm`)
Locally stored installation packages to eliminate dependency on external repositories.

## 3. Inventory Variables

To ensure reusability across multiple environments (Development, Staging, Production), all environment-specific data must be defined within the inventory file.

### Best Practice

`{{ variable_name }}`

## 4. Execution Workflow

The deployment process is divided into phases to enable effective troubleshooting and state validation.

---

### Playbook 1: Host Preparation (`elastic9-prepare-hosts.yml`)

**Scope:** All nodes

**Tasks:**
- Configure OS-level parameters (e.g., `sysctl`) to meet Elasticsearch requirements.
- Configure firewall rules (open ports 9200, 9300, 5601).
- Optional: Perform disk scanning and LVM configuration for data volumes.

---

### Playbook 2: Elasticsearch Deployment (`elastic9-playbook.yml`)

**Tasks:**
- Transfer Elasticsearch binaries from the Ansible control node to target nodes.
- Install Elasticsearch.
- Render configuration files.
- Initialize and form the cluster.

---

### Playbook 3: Kibana Deployment (`kibana9-playbook.yml`)

**Tasks:**
- Transfer Kibana binaries from the Ansible control node to Kibana nodes.
- Install and configure Kibana.

---

### Playbook 4: Metricbeat Deployment (`metricbeat9-playbook.yml`)

**Tasks:**
- Transfer Metricbeat binaries from the Ansible control node to all nodes.
- Install and configure Metricbeat.

## 5. Execution Command

Run the following command to execute playbooks:

```bash
ansible-playbook -i inventory.ini <script_name>


## 6. General Recommendations

> [!IMPORTANT]
> - The provided scripts are designed for general use and may require adjustments to align with specific environments and requirements.
> - Thoroughly test all scripts in non-production environments before deployment.
> - Maintain scripts in a version-controlled repository (e.g., Git) to track changes and ensure consistency.