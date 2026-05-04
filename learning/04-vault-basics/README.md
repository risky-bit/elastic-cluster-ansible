# 04 — ansible-vault Basics

The consultant's `cluster.ini` has plaintext passwords in a file you'd commit to git. ansible-vault solves that: it encrypts secrets at rest so you can commit the encrypted file safely. Decryption happens at runtime, in memory, using a password you supply.

---

## How it works

You write a YAML file of secrets, encrypt it with ansible-vault, and commit the encrypted blob. In a playbook, you reference those variables exactly as if they were plaintext — `{{ es_elastic_password }}` — and Ansible decrypts at runtime if you provide the vault password. Anyone without the vault password sees only ciphertext.

---

## The vault password

Everything hinges on one password that decrypts the vault. You have two ways to supply it:

**Prompted at runtime:**
```bash
ansible-playbook playbook.yml --ask-vault-pass
```
Ansible stops and asks. Good for interactive use.

**From a file:**
```bash
ansible-playbook playbook.yml --vault-password-file .vault_pass
```
`.vault_pass` is a plain text file containing only the password. It must be gitignored — and it already is in our `.gitignore`. Used for automation (Semaphore, CI) where you can't type a password interactively.

---

## Exercise — create, view, edit, use

Work from the `learning/04-vault-basics/` directory for all commands below.

### 1. Create an encrypted vault file

```bash
cd learning/04-vault-basics
ansible-vault create vault.yml
```

Ansible asks for a new vault password, then opens your default editor (`$EDITOR`). Type some fake variables:

```yaml
dummy_password: "s3cr3t"
dummy_api_key: "abc123xyz"
```

Save and close. Ansible encrypts the file. If you `cat vault.yml` now, you'll see the ciphertext header:

```
$ANSIBLE_VAULT;1.1;AES256
...long hex string...
```

That's what gets committed. The plaintext never touches disk after the editor closes.

### 2. View without decrypting to disk

```bash
ansible-vault view vault.yml
```

Asks for the password, prints the plaintext to stdout. Nothing written to disk.

### 3. Edit in place

```bash
ansible-vault edit vault.yml
```

Decrypts into a temp file, opens your editor, re-encrypts on save. The plaintext temp file is cleaned up automatically.

### 4. Use vault variables in a playbook

Create a file `use-vault.yml` in this directory:

```yaml
---
- name: Vault demo
  hosts: local
  gather_facts: false

  vars_files:
    - vault.yml

  tasks:
    - name: Print the dummy password
      ansible.builtin.debug:
        msg: "The password is: {{ dummy_password }}"
```

Run it:

```bash
ansible-playbook -i ../01-hello-world/inventory.ini use-vault.yml --ask-vault-pass
```

Ansible loads `vault.yml`, decrypts it in memory, and `{{ dummy_password }}` resolves to `s3cr3t`. The decrypted value never touches disk.

---

## How `vars_files` works

`vars_files` is a list of files to load as variables before tasks run. Ansible handles encrypted files transparently — you don't need any special syntax to use a vault file vs a plain vars file. The only difference is you must supply the vault password at runtime.

In production, we won't use `vars_files` directly — instead, vault files live in `group_vars/all/vault.yml` and Ansible loads them automatically based on the inventory group structure you learned in step 03. Same decryption, no explicit `vars_files` needed.

---

## `encrypt_string` — encrypting a single value

Sometimes you want to put one encrypted value inline in an otherwise-plaintext file:

```bash
ansible-vault encrypt_string 's3cr3t' --name 'dummy_password'
```

Output:

```yaml
dummy_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  ...hex...
```

Paste that block directly into any vars file. Ansible decrypts it at runtime the same way. Useful when most vars are non-sensitive and only one or two need encrypting.

---

## The `.vault_pass` file for local use

For day-to-day work you don't want to type the password every run. Create:

```bash
echo 'your-vault-password' > .vault_pass
chmod 600 .vault_pass
```

Then configure `ansible.cfg` to always use it:

```ini
[defaults]
vault_password_file = .vault_pass
```

With that in place, `ansible-playbook` decrypts silently. The file is gitignored. On a fresh clone, you recreate it (or pull it from a secrets manager). On the automation host, Semaphore injects it via an environment variable or mounted secret.

---

## What vault does NOT protect

- Variables printed by `debug` tasks — if you print `{{ dummy_password }}` in a playbook, the decrypted value appears in the terminal output and any log file. Use `no_log: true` on tasks that handle secrets:

```yaml
- name: Set keystore password
  shell: echo "{{ keystore_password }}" | elasticsearch-keystore add ...
  no_log: true
```

- The vault password itself — if `.vault_pass` is compromised, all vaults encrypted with it are compromised. Treat it like a root password.

---

## Key commands summary

| Command | What it does |
|---|---|
| `ansible-vault create file.yml` | Create a new encrypted file |
| `ansible-vault view file.yml` | Print decrypted contents to stdout |
| `ansible-vault edit file.yml` | Edit in place (decrypt → editor → re-encrypt) |
| `ansible-vault encrypt file.yml` | Encrypt an existing plaintext file |
| `ansible-vault decrypt file.yml` | Decrypt to plaintext on disk (careful) |
| `ansible-vault encrypt_string 'val' --name 'key'` | Encrypt a single inline value |
| `ansible-vault rekey file.yml` | Change the vault password |

Next: [05 — Jinja2 templates](../05-jinja2-templates/) — how `elasticsearch.yml.j2` becomes a real config file on the target host.
