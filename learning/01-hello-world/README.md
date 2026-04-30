# 01 — Hello World

**Goal:** Install Ansible, understand its three core concepts, run your first command and playbook against localhost.

---

## Mental model before you touch anything

Ansible works by SSHing into machines and running tasks in order. That's it. No agent on the target. No daemon. You run a command from your laptop (or automation host), Ansible connects, does the work, disconnects.

Three concepts you need before anything makes sense:

| Concept | What it is | File in this exercise |
|---|---|---|
| **Inventory** | The list of machines to target | `inventory.ini` |
| **Module** | A built-in action Ansible knows how to do (ping, copy a file, install a package, etc.) | Used inline in commands and playbooks |
| **Playbook** | A YAML file describing what to do, on which hosts, in what order | `hello.yml` |

---

## Step 1 — Install Ansible

```bash
pip3 install ansible
```

Verify it worked:

```bash
ansible --version
```

You should see something like `ansible [core 2.x.x]`. The Python interpreter it found will be listed too — that's fine, it's using Homebrew's Python 3.11.

---

## Step 2 — Look at the inventory

Open [inventory.ini](inventory.ini). It declares one host (`localhost`) in a group called `local`, and tells Ansible to connect to it locally (no SSH needed — useful for testing on your own machine).

```ini
[local]
localhost ansible_connection=local
```

`ansible_connection=local` is a **host variable** — it overrides the default SSH transport just for this host. On real servers you drop this and Ansible uses SSH.

---

## Step 3 — Run an ad-hoc command

An ad-hoc command is a one-liner — no playbook file needed. The `-m` flag picks the module.

```bash
cd learning/01-hello-world

ansible all -m ping -i inventory.ini
```

Expected output:

```
localhost | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

What just happened: Ansible read the inventory, found `localhost`, connected to it (locally), ran the `ping` module (which just checks the connection and Python availability — it does not send an ICMP ping), got a response.

`changed: false` is important. It means the ping module made no changes to the system. Most read-only operations come back `changed: false`. Modules that write files, install packages, etc. come back `changed: true` the first time, and `changed: false` on subsequent runs if the system is already in the right state. This is **idempotency** — a core Ansible concept.

---

## Step 4 — Look at the playbook

Open [hello.yml](hello.yml). It has two tasks:

```yaml
- name: Ping the host
  ansible.builtin.ping:

- name: Print a message
  ansible.builtin.debug:
    msg: "Hello from Ansible. Running on: {{ inventory_hostname }}"
```

`ansible.builtin.ping` — same module as above, but declared in a playbook.

`ansible.builtin.debug` — prints a message. `{{ inventory_hostname }}` is a **variable** — Ansible fills it in with the name of the current host (`localhost` in our case). The double-brace syntax is Jinja2 templating. You'll see it everywhere in real playbooks and config templates.

`gather_facts: false` at the top — by default Ansible runs a "setup" task first that collects system facts (OS version, IP addresses, memory, etc.) from every host. We're skipping that here to keep output clean. In real playbooks you usually leave it on.

---

## Step 5 — Run the playbook

```bash
ansible-playbook -i inventory.ini hello.yml
```

Expected output:

```
PLAY [Hello World] *************************************************************

TASK [Ping the host] ***********************************************************
ok: [localhost]

TASK [Print a message] *********************************************************
ok: [localhost] => {
    "msg": "Hello from Ansible. Running on: localhost"
}

PLAY RECAP *************************************************************
localhost                  : ok=2    changed=0    unreachable=0    failed=0    skipped=0
```

The **PLAY RECAP** at the bottom is your summary. Watch `failed=0` and `unreachable=0`. Any non-zero there means something went wrong.

---

## What you just learned

- Ansible needs an inventory (who) and a playbook or module (what).
- `ansible` runs ad-hoc commands. `ansible-playbook` runs YAML playbooks.
- Modules are idempotent by design — run the same playbook twice and the second run changes nothing.
- `{{ variable }}` is Jinja2 templating. It's used in playbooks and in the config file templates you'll see in the consultant's bundle.
- `changed: false` vs `changed: true` tells you whether the system state was modified.

Next: [02-prepare-hosts-walkthrough](../02-prepare-hosts-walkthrough/) — reading and understanding the consultant's `prepare-hosts` playbook.
