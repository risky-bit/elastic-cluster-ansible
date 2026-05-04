# 03 — Variable Precedence and Inventory Structure

Ansible has 22 documented variable precedence levels. You don't need to memorise all of them. You need to understand five layers — the ones you'll actually use — and the one rule that governs them all.

---

## The one rule

**Higher precedence wins. More specific beats more general.**

Host variables beat group variables. Group variables beat global variables. Variables passed at runtime beat everything declared in files.

---

## The five layers you'll use (lowest to highest)

```
1. group_vars/all/          ← applies to every host
2. group_vars/<group>/      ← applies to hosts in that group
3. host_vars/<hostname>/    ← applies to one specific host
4. play vars / set_fact     ← declared inside a playbook at runtime
5. -e "var=value"           ← passed on the command line; overrides everything
```

If you define `es_heap_mb=1024` in `group_vars/all/vars.yml` and then set `es_heap_mb=4096` in `group_vars/elastic_data_nodes/vars.yml`, every data node gets 4096 and every other node gets 1024. The data-node group is more specific, so it wins.

---

## What the consultant's bundle does (and why it's a problem)

Everything lives in one flat `[all:vars]` block inside `cluster.ini`:

```ini
[elastic_nodes]
node01  ansible_host=10.43.1.x  ansible_user=root  ansible_password=...  roles="master,ingest,data"

[all:vars]
es_version=9.2.4
elasticsearch_password=...plaintext...
kibana_system_password=...plaintext...
```

This works but has three problems:

1. **Secrets in plaintext in a file you'd want to commit.** Passwords, keystore credentials, and encryption keys are all readable by anyone with repo access.
2. **No separation between node types.** All three nodes get `roles="master,ingest,data"` as an inline host variable — there's no group to represent "master-only" or "data-only" nodes, which is what production requires.
3. **One inventory file does everything.** Dev IPs, prod IPs, secrets, and structural config are all in the same place. Changing an IP for dev means touching the same file as sensitive credentials.

---

## How we'll structure it for production

```
ansible/
└── inventory/
    ├── dev.ini                     # committable; placeholder IPs only
    ├── prod.ini                    # GITIGNORED; real IPs and hostnames
    └── group_vars/
        └── all/
            ├── vars.yml            # non-sensitive defaults (es_version, ports, paths)
            └── vault.yml           # GITIGNORED; all secrets, ansible-vault encrypted
```

Later, when we split node roles, we'll add:

```
        ├── elastic_master_nodes/
        │   └── vars.yml            # master-specific overrides (heap, roles list)
        └── elastic_data_nodes/
            └── vars.yml            # data-specific overrides (heap, disk threshold)
```

---

## How `group_vars` maps to inventory groups

Ansible looks for a directory named after each group a host belongs to. If a host is in both `elastic_nodes` and `elastic_master_nodes`, Ansible loads `group_vars/elastic_nodes/` **and** `group_vars/elastic_master_nodes/` for that host. The more specific group wins if the same variable is defined in both.

There is also a special group called `all` — every host is always in `all`. So `group_vars/all/vars.yml` is the right place for defaults that apply to every node in the cluster.

---

## Inline host vars vs group_vars

In the consultant's inventory, variables are written inline per host:

```ini
node01  ansible_host=10.43.1.21  roles="master,ingest,data"  node_zone="zone-1"
```

In production, you keep only connection-related variables inline (because they're host-specific by definition):

```ini
node01  ansible_host=10.0.0.21  ansible_user=ansible_svc
```

Everything else moves to `group_vars/` or `host_vars/`. This keeps the inventory file readable and separates *where to connect* from *how to configure*.

---

## The `default()` filter

When a variable might not be defined, Jinja2 raises an error. The `default()` filter prevents that:

```yaml
when: configure_disks | default(true)
```

This means: use `configure_disks` if it's defined; otherwise behave as if it's `true`. You saw this in `prepare-hosts.yml`. It's a safety valve — useful when a variable is optional and has a sensible fallback.

Without it:

```yaml
when: configure_disks   # fails with "undefined variable" if not set
```

---

## Variable types you'll encounter in the ES playbooks

| Variable | Where it lives | Example |
|---|---|---|
| Connection vars | Inline in inventory | `ansible_host`, `ansible_user` |
| Structural vars | `group_vars/all/vars.yml` | `es_version`, `http_port`, `mount_point` |
| Node-type vars | `group_vars/<role>/vars.yml` | `es_heap_mb`, `disk_size_threshold` |
| Secrets | `group_vars/all/vault.yml` | `es_elastic_password`, `keystore_password` |
| Runtime facts | Set by Ansible at runtime | `ansible_hostname`, `ansible_default_ipv4` |
| Computed facts | Set with `set_fact` in playbooks | `es_major`, `node_roles_list` |

---

## Practical test

Open `vendor/consultant-bundle/ansible-archive/cluster.ini`. Find `es_heap_mb=1024` in `[all:vars]`. Ask yourself:

- Which file would this move to in our production layout? (`group_vars/all/vars.yml`)
- If master nodes need 2GB and data nodes need 16GB, where would you put those overrides? (`group_vars/elastic_master_nodes/vars.yml` and `group_vars/elastic_data_nodes/vars.yml`)
- If you wanted to temporarily override heap to 512MB for a single test run without editing any file, how? (`ansible-playbook ... -e "es_heap_mb=512"`)

Next: [04 — ansible-vault basics](../04-vault-basics/) — how secrets actually get encrypted and used.
