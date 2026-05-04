# Binaries

RPM files are not committed. Transfer them to the automation host via USB and verify SHA256 before use.

All packages are for `x86_64` RHEL 9.

---

## Required packages

| Package | Version | SHA256 |
|---|---|---|
| `elasticsearch-9.3.4-x86_64.rpm` | 9.3.4 | `fa36d58b0c3904e5b37b5ab2acdbe2a8f32d439f881c110dc2e7ae2f06b4a9d1` |
| `kibana-9.3.4-x86_64.rpm` | 9.3.4 | `a28c1a269de240e1c17ddcf340f603aa37598e2ed22b259709f0c159bfe2b5e3` |
| `logstash-9.3.4-x86_64.rpm` | 9.3.4 | `1c51783ce06946edf9927e828b138309b2f610635c5f071d20596444961852e6` |
| `elastic-agent-9.3.4-x86_64.rpm` | 9.3.4 | `06313ec1dfcba486ef80726938aa4d422cfc4498ed2c1b707a39e882df546e2b` |

Verify with:

```bash
sha256sum <package>.rpm
```

---

## Notes

- All packages must be the same minor version (e.g., all 9.3.4). Mixed versions are unsupported.
- `elastic-agent` covers Fleet Server and cluster monitoring. No separate Metricbeat RPM needed.
- Place RPMs in `/opt/elastic-ansible/binaries/` on the automation host before running any install playbook.
