# 05 — Jinja2 Templates

Source file: `vendor/consultant-bundle/ansible-archive/elasticsearch.yml.j2`

A `.j2` file is a text file with placeholders. Ansible reads it, substitutes all the variables and logic, and writes the result to the target host as a plain file. The target host never sees the template — only the rendered output.

---

## The `template` module

```yaml
- name: Render elasticsearch.yml from template
  template:
    src: elasticsearch.yml.j2
    dest: /etc/elasticsearch/elasticsearch.yml
    owner: root
    group: root
    mode: '0644'
```

`src` is the `.j2` file on the controller. `dest` is where the rendered file lands on the target host. Every variable available to that task — inventory vars, group_vars, facts, set_facts — is available inside the template.

---

## Jinja2 syntax: three constructs

**`{{ expression }}`** — outputs a value. This is substitution.
```
cluster.name: {{ cluster_name }}
```
Becomes:
```
cluster.name: primary-cluster
```

**`{% statement %}`** — control flow. No output, just logic: `if`, `for`, `set`.
```
{% if setup_mode %}
cluster.initial_master_nodes: [...]
{% endif %}
```

**`{# comment #}`** — comment. Stripped from the output entirely.

---

## Walking through `elasticsearch.yml.j2`

### Lines 1–2 — `{% set %}`: local variables

```jinja2
{% set node_roles_list = roles.split(',') | map('trim') | list %}
{% set es_major = es_version.split('.')[0] | int %}
```

`{% set %}` declares a variable scoped to this template. Two things are computed up front so they can be reused below:

- `node_roles_list`: takes the host variable `roles` (a string like `"master,ingest,data"`), splits on comma, strips whitespace from each item, converts to a Python list → `['master', 'ingest', 'data']`
- `es_major`: takes `es_version` (e.g., `"9.2.4"`), splits on `.`, takes index 0 (`"9"`), converts to integer → `9`

The `|` is a **filter** — it pipes the value through a transformation. `split(',')`, `map('trim')`, `list`, `int` are all filters. You'll see them constantly.

---

### Line 20 — `default()` filter

```jinja2
cluster.name: {{ cluster_name | default('es-cluster') }}
```

If `cluster_name` is defined (it is, in the inventory), use it. If somehow it's not, fall back to `'es-cluster'` instead of erroring. You saw `default()` in playbooks too — same filter, same behaviour.

---

### Lines 26–27 — `inventory_hostname`

```jinja2
node.name: {{ inventory_hostname }}
node.attr.zone: {{ node_zone }}
```

`inventory_hostname` is an Ansible **magic variable** — always the name of the current host as written in the inventory. It's always available; you never need to define it. When Ansible renders this template for node01, `inventory_hostname` is `node01`. When it renders it for node02, it's `node02`. Same template file, different output per host.

`node_zone` is a regular host variable from the inventory (`zone-1`, `zone-2`, `zone-3`). Zone awareness lets ES distribute shards across zones so a zone failure doesn't lose all copies of a shard.

---

### Lines 33–37 — `{% if %}` and `{% for %}` together

```jinja2
{% if (ignore_roles | default(false)) %}
# node.roles: [ ]
{% else %}
node.roles: [ {% for role in node_roles_list if not (es_major >= 9 and role == 'ml') %}{{ role }}{% if not loop.last %}, {% endif %}{% endfor %} ]
{% endif %}
```

The outer `if` controls whether roles are rendered at all. When `ignore_roles` is true (used during bootstrap — the first master node starts without explicit roles to let ES auto-configure), the line is commented out. When false, the `for` loop builds the role list.

The `for` loop has an **inline filter**: `if not (es_major >= 9 and role == 'ml')` — skip the `ml` role on ES 9+. ML nodes require a Platinum or higher license; Basic license doesn't include it. The consultant built this guard in to avoid a startup error on ES9.

`loop.last` is a Jinja2 loop variable that's `true` when you're on the final iteration — used here to suppress the trailing comma. Output for a 3-role node:

```
node.roles: [ master, ingest, data ]
```

---

### Lines 90–96 — `setup_mode` and `groups`

```jinja2
{% if (setup_mode | default(false)) %}
cluster.initial_master_nodes: ["{{ groups['elastic_nodes'][0] }}"]
discovery.seed_hosts: ["{{ groups['elastic_nodes'][0] }}:{{ transport_port | default(9300) }}"]
{% else %}
# cluster.initial_master_nodes: [{{ initial_master_nodes }}]
discovery.seed_hosts: [{{ seed_hosts }}]
{% endif %}
```

`groups` is another magic variable — a dict of all inventory groups mapping to their host lists. `groups['elastic_nodes'][0]` is the first host in the `elastic_nodes` group.

**Why two modes:**

ES 8+ requires `cluster.initial_master_nodes` to be set when forming a cluster for the first time. But once the cluster is running, that setting must be **removed** — leaving it in can cause split-brain on restart (each node thinks it should be the first master). The `setup_mode` flag controls which version of the config is written:

- `setup_mode: true` → bootstrap config: `initial_master_nodes` is set, `discovery.seed_hosts` points to just the first master
- `setup_mode: false` → production config: `initial_master_nodes` is commented out, `seed_hosts` lists all three nodes

The playbook renders the template twice: once in setup mode to bootstrap, once in normal mode after the cluster is up. That's the restart you see at step 8 of `elastic9-playbook.yml`.

---

### Line 103 — `action.auto_create_index`

```
action.auto_create_index: +.kibana*,+kibana-int,+logstash-*,+idx_*,+pssdata*,+error*,.security,...
```

This controls which indices Elasticsearch will create automatically when data is written to a non-existent index. The `+` prefix allows; no prefix also allows but is an older syntax. `.security`, `.monitoring*`, etc. are system indices ES itself creates.

`pssdata*` and `error*` are custom patterns — almost certainly from the client's application. These should not be carried into our production config blindly; we need to understand what writes to those indices before committing to allowing auto-creation.

---

### Lines 119–148 — TLS (xpack.security)

```
xpack.security.transport.ssl.keystore.path: certificates/certfile.p12
xpack.security.http.ssl.keystore.path: certificates/certfile.p12
```

Both transport (node-to-node) and HTTP (client-to-node) TLS use the same `.p12` keystore file. A `.p12` (PKCS#12) bundles the certificate, private key, and CA chain into one encrypted file. The path is relative to `/etc/elasticsearch/`, so the actual file is at `/etc/elasticsearch/certificates/certfile.p12`.

Keystore passwords are not in this template — they're stored in the ES keystore (a separate encrypted store managed by `elasticsearch-keystore`) and set by the playbook task you saw in step 4 of `elastic9-playbook.yml`.

`xpack.security.transport.ssl.verification_mode: certificate` means nodes verify each other's certificates but not hostnames. `full` would also check hostnames — more secure, but requires certs to have the correct SANs. For an internal cluster on a single subnet, `certificate` is the common pragmatic choice.

---

## What the rendered output looks like

When Ansible runs `template` for node01 with `setup_mode: false`, it produces something like:

```yaml
cluster.name: primary-cluster
node.name: node01
node.attr.zone: zone-1
cluster.routing.allocation.awareness.attributes: zone
node.roles: [ master, ingest, data ]
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: "10.0.0.21"
http.port: 9200
transport.port: 9300
discovery.seed_hosts: ["node01:9300", "node02:9300", "node03:9300"]
...
```

The template is rendered separately for each host in the play. Node02 gets the same structure but with its own IP, zone, and hostname.

---

## Three things to watch in production

1. **`pssdata*` and `error*` in `auto_create_index`** — these are client-specific. Understand what writes to them before carrying them forward.

2. **`groups['elastic_nodes'][0]` for bootstrap** — this assumes the first host alphabetically (or in declaration order) in the inventory is the intended first master. It's implicit. In production we'll make this explicit via `es_first_master` in vars.

3. **`setup_mode` logic** — the two-phase template render is correct, but if the playbook is interrupted between the two renders, nodes could end up with `initial_master_nodes` still set after the cluster is live. Something to verify during dev cluster testing.

---

That's the last Phase A step. You've now read every layer the playbooks touch: OS prep, inventory structure, variable resolution, secrets management, and config templating. Phase B is setting up the automation host.
