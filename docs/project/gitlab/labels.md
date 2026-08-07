# GitLab labels (LTZ)

| Label | Purpose |
|-------|---------|
| `phase::m0` | Foundations / lab |
| `phase::m1` | Device trust MVP (attestor, agent) |
| `phase::m2` | Tenant plug-in (Intune, CA compliant device) |
| `phase::f1` | Future user CBA / FIDO |
| `phase::f2` | Future AWX management depth |
| `phase::f3` | Future workload identity / SPIRE |
| `blocked::entra` | Waiting on REQ-M* or REQ-F* |
| `area::device` | Device / compliance plane |
| `area::user` | User auth (SSSD done; CBA future) |
| `area::lab` | Lab-only |
| `area::client` | ltz-client production tree |

**Deprecated:** `phase::p4` / “TPM-CBA” as MVP phase — CBA is `phase::f1`.
