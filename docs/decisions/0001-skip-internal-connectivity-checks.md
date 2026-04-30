# 0001 — Skip Intra-Cluster Connectivity Checks

**Date:** 2026-04-28
**Status:** Accepted

---

## Context

Pre-flight connectivity checks — Ansible `wait_for` tasks that probe Elasticsearch transport ports (9300) and HTTP ports (9200) between nodes before cluster formation — are a common pattern to surface network issues early. They add playbook complexity and runtime cost. The question is whether that cost is worth it in this environment.

All cluster nodes sit on a single flat subnet with no internal firewalling between them. The infrastructure team has confirmed no host-based firewall rules (`firewalld`) are in place on cluster nodes that would block inter-node traffic. External segmentation exists at the perimeter only.

---

## Decision

Skip intra-cluster connectivity checks in playbooks. Do not add `wait_for` or `uri` pre-flight tasks that probe ES ports between hosts.

The port that matters — SSH (22) — is already implicitly checked by Ansible itself before any task runs. If SSH is up, the network path exists, and there is no additional firewall to block ES ports.

---

## Consequences

- Playbooks are simpler and run faster.
- If Elasticsearch fails to form a cluster, the error surfaces from the ES logs directly rather than from a pre-flight check. This is acceptable: the failure mode is no harder to diagnose.
- A missing pre-flight check will not mask a misconfigured `network.host` or `discovery.seed_hosts` setting — those produce their own clear errors.

---

## Revisit if

- A firewall (host-based or network-level) is introduced between cluster nodes.
- Playbooks are adapted for a multi-subnet or multi-datacenter topology.
- A pattern of hard-to-diagnose cluster formation failures emerges in practice.
