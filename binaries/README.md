# Binaries

RPM files are not committed. Pull them from the internal mirror on each fresh clone and verify SHA256 before use.

All packages are for `x86_64` RHEL 9.

---

## Required packages

| Package | Version | SHA256 |
|---|---|---|
| `elasticsearch-*.x86_64.rpm` | TBD | TBD |
| `kibana-*.x86_64.rpm` | TBD | TBD |
| `logstash-*.x86_64.rpm` | TBD | TBD |
| `elastic-agent-*.x86_64.rpm` | TBD | TBD |
| `metricbeat-*.x86_64.rpm` | TBD | TBD |

Fill in version and SHA256 when packages are staged. Verify with:

```bash
sha256sum <package>.rpm
```

---

## Notes

- All packages must be the same minor version (e.g., all 9.x.x). Mixed minor versions are unsupported.
- `elastic-agent` covers Fleet Server and lightweight monitoring. `metricbeat` is used only if Fleet-managed monitoring is not viable.
- Place RPMs in this directory before running any playbook that installs Elastic Stack components.
