# ltz_compliance

Host-side compliance **assertions** and a machine-readable report for ops/Intune correlation.

- Does **not** replace Intune discovery (that stays read-only JSON).
- Checks expected LTZ artifacts: status.json, disk encryption, optional role markers.
- Safe for `ansible-pull` (assert / report only by default).

## Enable

```yaml
ltz_enable_compliance: true
ltz_compliance_strict: false   # true = fail play on missing requirements
```
