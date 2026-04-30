# 02 — Annotated Walkthrough: `elastic9-prepare-hosts.yml`

Source file: `vendor/consultant-bundle/ansible-archive/elastic9-prepare-hosts.yml`

This is the first real playbook to read. It prepares the OS on every Elasticsearch node before any software is installed. Read it open alongside this file.

---

## The header

```yaml
- name: Prepare elastic hosts
  hosts: elastic_nodes
  become: true
  gather_facts: false
```

Four lines — all of them matter.

**`hosts: elastic_nodes`** — which machines to run on. `elastic_nodes` is a group name defined in the inventory (`cluster.ini`). Ansible looks up that group, finds the IPs, and SSHes into each one.

**`become: true`** — run every task as root (via sudo). Without this, you can't write to `/etc/sysctl.conf` or manage services. Set at the play level, it applies to every task unless overridden.

**`gather_facts: false`** — by default Ansible runs a hidden first task called "Gathering Facts" that collects system information (OS version, IP addresses, memory, etc.) and stores it in variables you can use later. Skipping it speeds up the run. This playbook doesn't use any fact variables, so skipping is fine. In playbooks that do use facts (e.g., `ansible_os_family` to branch on RHEL vs Debian), you leave this on.

---

## The vars block

```yaml
vars:
  threshold: "{{ disk_size_threshold_large if 'data' in roles else disk_size_threshold_small }}"
```

`vars` defined here are play-scoped — available to every task in this play.

`threshold` uses an inline Jinja2 conditional: if the current host's `roles` variable contains the string `data`, use the large threshold; otherwise use the small one. `roles` is a host variable set per-host in the inventory — in the consultant's setup, each node has `roles="master,ingest,data"`. This is how one playbook behaves differently on different node types.

`disk_size_threshold_large` and `disk_size_threshold_small` are not defined in this playbook — they're expected to come from `group_vars` or the inventory. If they're missing, the playbook fails. That's a gap in the consultant's bundle: those variables aren't declared anywhere visible.

---

## Section 1 — OS kernel tuning

```yaml
- name: Ensure vm.swappiness is set to 1
  ansible.builtin.lineinfile:
    path: /etc/sysctl.conf
    line: "vm.swappiness=1"
    state: present
    create: yes
    backup: yes
```

**`ansible.builtin.lineinfile`** — ensures a specific line exists in a file. If it's already there, nothing happens (`changed: false`). If it's missing, Ansible adds it. That's idempotency: run this ten times, the result is the same as running it once.

`create: yes` — create the file if it doesn't exist.
`backup: yes` — save a timestamped copy of the original before modifying. Useful if you need to roll back manually.

**Why these three settings:**

- `vm.swappiness=1` — tells the kernel to avoid using swap memory unless absolutely forced. Elasticsearch is a JVM application managing its own heap; if the OS starts swapping heap pages to disk, ES latency spikes and the node can fall out of the cluster. Value of 1 (not 0) avoids a known kernel bug where 0 can cause OOM-killer issues.

- `vm.max_map_count=1048576` — Elasticsearch uses memory-mapped files (mmap) for its Lucene index segments. Each segment requires a memory map entry. The default Linux limit (~65530) is too low; ES will refuse to start with a startup check error if this isn't set. This is non-negotiable.

- `net.ipv4.tcp_retries2=5` — controls how many times the kernel retries a TCP connection before giving up. Default is 15, which can mean a 13-minute wait before a dead connection is detected. Setting it to 5 means Elasticsearch detects failed nodes in roughly 6 seconds instead. Important for fast cluster re-election when a master dies.

```yaml
- name: Ensure elasticsearch has nofile limit in limits.conf
  ansible.builtin.lineinfile:
    path: /etc/security/limits.conf
    line: "elasticsearch  -  nofile  65535"
```

`nofile` is the maximum number of open file descriptors the `elasticsearch` user can have. ES opens many files simultaneously (index segments, network sockets, log files). The default Linux limit (1024 or 4096 depending on distro) causes `Too many open files` errors under load.

```yaml
- name: Apply all changes
  shell: |
    sudo sysctl -p
    echo "applied"
```

`sysctl -p` reloads `/etc/sysctl.conf` into the running kernel — without it, the `vm.max_map_count` changes only take effect after a reboot. Note: this task uses `shell` with `sudo` inside it, even though `become: true` is already set at the play level. The redundant `sudo` is harmless but sloppy. An `ansible.posix.sysctl` module exists and is cleaner — we'll use it in our production version.

---

## Section 2 — Disk setup (LVM)

```yaml
- name: Prepare all disks
  when:
    - configure_disks | default(true)
  shell: |
    ...200 lines of bash...
```

**`when`** — a conditional. The task only runs if the expression is true. `configure_disks | default(true)` means: use the `configure_disks` variable if it's defined; if not, default to `true`. This lets you skip the disk setup on a specific host by setting `configure_disks=false` in the inventory. Useful for dev VMs that don't have extra disks.

The `|` here is a Jinja2 **filter** — `default(true)` is a filter applied to the variable. You'll see filters constantly: `| lower`, `| join(',')`, `| list`, `| int`, etc.

**What the shell script does:**
1. Finds all block devices larger than `threshold` bytes (so it doesn't accidentally touch the OS disk)
2. Skips any disk that's already mounted (safety check)
3. Creates an LVM physical volume (`pvcreate`), volume group (`elkvg`), and logical volume (`elklv`) from each qualifying disk
4. Formats as XFS
5. Gets the UUID, writes an `fstab` entry with `nofail` (won't block boot if the disk is missing), mounts it

**The idempotency problem:** this is a shell script, not Ansible tasks. The script has manual `if` checks to skip steps that are already done (e.g., skips `pvcreate` if the disk is already a PV). That hand-rolled idempotency works, but it's fragile — a partial failure mid-script leaves the system in an unknown state with no clear Ansible `changed` signal. In production we'll replace this with discrete Ansible tasks using the `community.general.lvg`, `community.general.lvol`, and `community.general.filesystem` modules.

---

## Section 3 — Firewall

```yaml
- name: Start Firewalld service
  systemd:
    name: firewalld
    enabled: yes
    state: started
    daemon_reload: yes
```

**`ansible.builtin.systemd`** — manages systemd services. `enabled: yes` means "enable on boot". `state: started` means "ensure it's running right now". If it's already running, `changed: false`. If it was stopped, Ansible starts it and reports `changed: true`.

```yaml
- name: Open TCP port in firewalld (HTTP Elastic port)
  command: firewall-cmd --zone={{ firewall_zone }} --add-port={{ http_port }}/tcp --permanent
  become: true
  when: inventory_hostname in groups['elastic_nodes']
```

**`ansible.builtin.command`** — runs a shell command, but without a shell. Safer than `shell` (no pipes, no redirection), but also not idempotent — it runs every time regardless of current state. `firewall-cmd` is the RHEL firewall CLI.

`{{ firewall_zone }}` and `{{ http_port }}` come from inventory vars. `{{ http_port }}` is `9200` and `{{ transport_port }}` is `9300` in the consultant's `cluster.ini`.

**Dead code:**
```yaml
- name: Open TCP port in firewalld (Kibana port)
  command: firewall-cmd --zone={{ firewall_zone }} --add-port={{ kibana_port }}/tcp --permanent
  become: true
  when: inventory_hostname in groups['kibana_nodes']
```

This task will never run. The play targets `elastic_nodes`. Even if a host is in *both* `elastic_nodes` and `kibana_nodes`, this condition would evaluate to true — but in the consultant's inventory, Kibana runs on node 1 which *is* in both groups. So it's not dead code in their setup; it's just confusing placement. In production we'll have a dedicated `prepare-hosts` play for Kibana nodes.

---

## Key concepts introduced in this playbook

| Concept | Where you saw it |
|---|---|
| `become: true` | Play header — privilege escalation |
| `gather_facts: false` | Play header — skip fact collection |
| `hosts: <group>` | Play header — targets a group from inventory |
| `ansible.builtin.lineinfile` | sysctl and limits tasks — idempotent line management |
| `ansible.builtin.shell` | sysctl apply, disk setup — arbitrary shell, not idempotent by default |
| `ansible.builtin.command` | firewall tasks — runs a binary, no shell features |
| `ansible.builtin.systemd` | firewalld task — service state management |
| `when:` conditional | disk setup, firewall — task-level guards |
| `| default(value)` filter | `configure_disks | default(true)` — safe variable access |
| Play-level `vars:` | `threshold` — scoped to this play |

---

## What we'd change for production

1. **The `shell` task for `sysctl -p`** — replace with `ansible.posix.sysctl` module.
2. **The disk setup shell script** — replace with `community.general.lvg`, `community.general.lvol`, `community.general.filesystem`, and `ansible.posix.mount` tasks. Discrete, readable, properly idempotent.
3. **`ansible_user=root`** — use a service account with sudo, not root directly.
4. **`command: firewall-cmd`** — replace with `ansible.posix.firewalld` module (idempotent, no `--reload` needed).
5. **`disk_size_threshold_large/small` undefined** — these must be declared in `group_vars` before this playbook can run cleanly.

Next: [03 — Variable precedence and inventory structure](../03-variables-and-inventory/) — how Ansible decides which value wins when the same variable is defined in multiple places.
