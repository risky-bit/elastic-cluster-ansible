# Elasticsearch Cluster — Ansible Deployment

Ansible automation for an 8-node production Elasticsearch cluster running on air-gapped RHEL. The repo doubles as a learning artifact: the `learning/` folder captures the step-by-step journey from zero Ansible knowledge to a fully automated deployment. Production playbooks, inventory, and secrets are kept separate from learning exercises and are either gitignored or use placeholder values.

## Phased plan

| Phase | Goal | Location |
|---|---|---|
| A | Learn Ansible mental model | Laptop, `learning/` |
| B | Set up repo and tooling on automation host | Automation host |
| C | Validate on dev VMs, then deploy to production | Dev VMs → production cluster |

See [docs/plan.md](docs/plan.md) for the full step-by-step breakdown.
