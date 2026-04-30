# Project: Production Elasticsearch Cluster — Ansible Deployment

This repo serves two purposes:
1. **Learning artifact** — a first-time Ansible journey, captured in the `learning/` folder.
2. **Production automation source** — playbooks, inventory, infra-as-code for an 8-node Elastic Stack deployment.

The author is a data engineer building this from scratch. A consultant supplied a partial Ansible bundle (3-node dev template); a colleague supplied a Semaphore UI Compose stack (originally for a Kubernetes deployment). Both are starting points, not finished work.

---

## Sanitization rules — read first

This repo may be made public for portfolio purposes. Even when private, treat all contributors as if it could be.

**Never write:**
- The organization name, jurisdiction, ministry, or any identifying client detail.
- Real production IPs (only the documented placeholder range below).
- Real hostnames, real usernames, real passwords, real cert content.
- Names of colleagues, vendors, consultants.

**Use instead:**
- "the organization" / "the client" / "the production environment"
- Placeholder IPs from the documented range (`10.0.0.0/24` in committed files)
- Generic role names

Real values live in `inventory/prod.ini`, `inventory/group_vars/*/vault.yml`, and `binaries/` — all gitignored. Never propose committing them. Never echo real values back into committed files.

---

## Operator preferences

- No preamble, wrap-up, flattery, or restating the question. Lead with the recommendation.
- Don't default to agreement. Test assumptions. Challenge weak reasoning. Surface trade-offs.
- State confidence when uncertain. Acknowledge gaps over guessing.
- Skip generic disclaimers. Adult context.
- Show reasoning before conclusions, but keep it tight.
- Ask clarifying questions only when the answer would change direction. Otherwise make reasonable assumptions and note them briefly.
- Move fast on reversible decisions; go deeper on high-impact ones.
- Prefer practical over theoretical, clarity over completeness.
- Don't oversimplify. Don't compromise on depth.
- Always web-search for current verified info when relevant.

---

## Where the project is right now

**Phase A — Learning (active).** Operator has not yet run their first Ansible command. Next concrete action: laptop hello-world (`learning/01-hello-world/`).

The phased plan:

| Phase | What | Where |
|---|---|---|
| A | Learn Ansible mental model | Laptop, `learning/` folder |
| B | Set up repo + tooling on automation host | Real automation host |
| C | Test on dev VMs, then deploy prod | Real cluster |

Detailed step-wise plan lives in `docs/plan.md` (write this on first session if missing).

---

## Architecture target (high level)

- **8-node production Elasticsearch cluster**: 3 dedicated masters + 5 data+ingest nodes
- **2-node Logstash + Kibana + Fleet Server tier** (co-located)
- **2-node monitoring Elasticsearch cluster + NGINX** (a 3rd voting-only node is planned for safe quorum)
- **1 automation host** — open decision: keep dedicated, or fold into a monitoring node post-deployment
- **NFS-backed snapshot repository** — not yet provisioned by storage team
- **F5 VIPs**: production Kibana, monitoring Kibana, external NGINX entry
- **Elastic basic license** — TLS, native realm, alerting, APM, Fleet, lightweight uptime monitoring
- **Air-gapped RHEL** — no internet on cluster nodes; offline RPMs only

Full architecture spec lives in a separate plan document (not in this repo). Reference it when needed but do not paste its content here verbatim.

---

## Inherited material

### Consultant's Ansible bundle (`vendor/consultant-bundle/` once imported)

Covers ~40% of what's needed:
- 3-node dev inventory, single Kibana
- Playbooks: prepare-hosts, elastic9, kibana9, metricbeat9 (+ uninstall variants)
- Jinja2 templates for ES, Kibana, Metricbeat configs
- All nodes co-located (master+data+ingest on same boxes) — does **not** match the production split-role design

**Missing for production:**
- Logstash, Fleet Server, NGINX playbooks
- Dedicated-master vs data-node separation
- Voting-only node, monitoring cluster setup, NFS snapshot registration
- ILM / SLM policy application
- Vaulted secrets (consultant's inventory has plaintext passwords — do NOT carry that pattern forward)

### Colleague's Semaphore Compose stack (`infra/semaphore/`)

Source: a Kubespray/K8s deployment. Useful as a template, **not safe to drop in as-is**:
- Path mounts and env vars reference K8s/Kubespray — must be renamed for an Elasticsearch project
- Uses a custom-built Semaphore image — the build script was referenced but not supplied; obtain before running
- Podman, not Docker (RHEL-native; mostly compatible but not always)

---

## Decisions made (do not relitigate without reason)

1. **Skip intra-cluster connectivity checks.** All servers are on a single subnet with no internal firewalling. Documented in `docs/decisions/0001-skip-internal-connectivity-checks.md`.
2. **RPMs not committed.** Source documented in `binaries/README.md` with version + SHA256 table. Operator pulls from internal mirror on each fresh clone.
3. **Sensitive material gitignored.** `inventory/prod.ini`, `**/vault.yml`, `**/*.key`, `**/*.crt`, `**/*.p12`, `binaries/*.rpm`, `.vault_pass`.
4. **Stage learning before execution.** Laptop → read playbooks together → test VMs → prod. No skipping.
5. **Public-safe tone.** Repo content readable by an outsider without leaking client identity.

---

## Open decisions

- **Automation host placement.** Keep dedicated (cleaner blast radius, idle-ish but available for cert renewals, RPM mirror, scheduled re-runs) vs fold into a monitoring node post-deploy (one less VM but couples failure domains and adds SSH-key blast radius). Recommendation on file: keep dedicated. Operator to confirm.
- **Secrets workflow.** ansible-vault is the destination. Timing: introduce in Phase C, not Phase A — too much friction while learning.

---

## Repo structure

```
.
├── CLAUDE.md                   # this file
├── README.md                   # public-facing project description
├── .gitignore
├── learning/                   # Phase A artifacts — not for production use
│   ├── 01-hello-world/
│   ├── 02-prepare-hosts-walkthrough/
│   └── ...
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   ├── dev.ini             # placeholder IPs, committable
│   │   ├── prod.ini            # GITIGNORED
│   │   └── group_vars/
│   │       └── all/
│   │           ├── vars.yml
│   │           └── vault.yml   # GITIGNORED
│   ├── playbooks/
│   ├── templates/
│   └── roles/                  # later, when refactoring playbooks into roles
├── infra/
│   └── semaphore/              # Compose stack, vetted and renamed
├── binaries/
│   └── README.md               # version + SHA256 table; RPMs themselves gitignored
├── vendor/
│   └── consultant-bundle/      # original consultant material, untouched, for reference
└── docs/
    ├── plan.md                 # the phased plan
    ├── runbook.md
    └── decisions/              # ADR-style decision records
```

---

## How to work in this repo

- **Don't get ahead of the operator's current step.** If they're at Phase A Step 2, don't write production playbooks. Hold the line.
- **Default to reading before writing.** When asked about a file in `vendor/` or `infra/`, read it first.
- **Decision records:** for any non-obvious choice, propose creating a `docs/decisions/NNNN-*.md` file. ADR-lite — Context, Decision, Consequences, Revisit-if. ~20 lines, not 200.
- **Never echo secrets.** If the operator pastes a real password or IP in chat by accident, do not write it to disk. Flag it and continue with placeholders.
- **When suggesting commands**, assume RHEL 9, `dnf` not `yum`, `podman` not `docker`, `firewalld` not `iptables`.
- **Push back when warranted.** Operator explicitly wants challenge over agreement.
