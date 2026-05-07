# 0003 — NGINX Placement: Monitoring Nodes (Stopgap)

## Context

NGINX serves as an external auditable reverse proxy in front of the production Elasticsearch cluster. Its job is TLS termination for external clients hitting production ES and capturing every external API call (client IP, URI, method, status, latency, user-agent, body size) for compliance and audit purposes.

Flow: VIP (443) → NGINX on monitoring nodes → production data nodes.

Four placement options were evaluated:

- **LOGST nodes** — rejected. LOGST handles outbound ingest and production Kibana. Mixing inbound external proxy traffic with ingest CPU is the wrong direction.
- **Production data nodes** — rejected. Audit logs must not share a host with ES data. NGINX restarts risk destabilising data nodes. Heap competition.
- **Monitoring nodes (MON01/MON02)** — selected as stopgap. Monitoring traffic is internal and low-volume, spare CPU exists, and NGINX audit logs can ship directly into the monitoring ES cluster on the same box (short path).
- **Dedicated boxes** — correct end state. Deferred to Phase 9.

## Decision

NGINX runs on MON01 and MON02 for the current rollout. MON03 is ES-only and intentionally kept light as a quorum stabiliser.

This is a deliberate stopgap, not a permanent architecture. Phase 9 (dedicated NGINX boxes) is a real planned phase, not theoretical future work. If post-rollout metrics show NGINX load higher than expected, Phase 9 should be accelerated.

## Consequences

- NGINX audit logs co-locate with monitoring ES — acceptable for now, but creates a mild separation-of-concerns issue.
- LOGST nodes remain clean for ingest and Kibana duties.
- Data nodes are not exposed to proxy traffic or audit log I/O.
- Monitoring Kibana HA is unaffected — it runs on both MON01 and MON02. Single node loss does not cost visibility.

## Revisit If

- NGINX CPU or I/O on MON01/MON02 exceeds 30% sustained after rollout.
- Compliance requirements mandate full audit log isolation from monitoring data.
- A hardware refresh makes dedicated boxes available sooner than Phase 9.
