# 0002 — Main Cluster Initial Validation

**Date:** 2026-05-06
**Status:** Passed

---

## Context

First-run validation of the main Elasticsearch cluster following deployment via `install-elasticsearch.yml`. All checks run from NDCELSTMN01 against the cluster API.

---

## Cluster Health

```json
{
  "cluster_name" : "MOI-ELASTIC-PROD-CLUSTER",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 8,
  "number_of_data_nodes" : 5,
  "active_primary_shards" : 5,
  "active_shards" : 10,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "unassigned_primary_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "active_shards_percent_as_number" : 100.0
}
```

---

## Node Roles

| Node | IP | Role | Heap % | Disk % |
|---|---|---|---|---|
| NDCELSTMN01 | 172.20.70.71 | m | 25 | 0.71 |
| NDCELSTMN02 | 172.20.70.72 | m | 39 | 0.71 |
| NDCELSTMN03 | 172.20.70.73 | m | 38 | 0.71 |
| NDCELSTDN01 | 172.20.70.74 | di | 50 | 0.70 |
| NDCELSTDN02 | 172.20.70.75 | di | 27 | 0.70 |
| NDCELSTDN03 | 172.20.70.76 | di | 10 | 0.70 |
| NDCELSTDN04 | 172.20.70.77 | di | 38 | 0.70 |
| NDCELSTDN05 | 172.20.70.78 | di | 58 | 0.70 |

Roles confirmed: masters are master-only (`m`), data nodes are data+ingest (`di`).

---

## Shard Allocation

Zero unassigned shards. All 10 shards (5 primary + 5 replica) in STARTED state.

---

## Zone Awareness

| Node | Zone |
|---|---|
| NDCELSTMN01 | zone-1 |
| NDCELSTMN02 | zone-2 |
| NDCELSTMN03 | zone-3 |
| NDCELSTDN01 | zone-1 |
| NDCELSTDN02 | zone-2 |
| NDCELSTDN03 | zone-3 |
| NDCELSTDN04 | zone-1 |
| NDCELSTDN05 | zone-2 |

Each zone has one dedicated master and at least one data node. Zone-aware shard allocation active.

---

## License

```
type: basic
status: active
issued_to: MOI-ELASTIC-PROD-CLUSTER
```

---

## Bootstrap Cleanup

`cluster.initial_master_nodes` confirmed absent from all 3 master nodes post rolling restart. Cluster UUID locked — no further bootstrapping will occur.

---

## Result

All checks passed. Main cluster validated as production-ready on first deployment.
