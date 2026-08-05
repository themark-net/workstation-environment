# Importing into GitLab

## Option 1 — CSV import (GitLab Premium/Ultimate often; check your tier)

Project → Issues → Import · or bulk import via API.

Columns in `gitlab-issues.csv`:

`title`, `description`, `labels`, `weight`, `milestone`, `due_date`, `issue_type`

## Option 2 — API script (all tiers with token)

```bash
# Example pattern (requires glab or curl + PRIVATE-TOKEN)
# glab issue create --title "..." --label "..." --description "..."
```

A helper script outline is in `scripts/import-gitlab-issues.sh` at repo root (optional).

## Labels

Create labels from [labels.md](labels.md) **before** import so colors/descriptions exist.

## Milestones (suggested)

| Milestone | Phase |
|-----------|-------|
| LZT-P0 | Foundations |
| LZT-P1 | Device trust |
| LZT-P2 | Workload certs |
| LZT-P3 | SPIRE |
| LZT-P4 | TPM-CBA |
| LZT-P5 | Enforce |
| LZT-P6 | Handoff |

## Linking to Jira

Each description includes:

```text
Jira-Backlog-Key: LZT-S01
Jira: (fill after import) LZT-123
```

With GitLab Jira integration, mention `LZT-123` in MR/issue titles to auto-link.

## Multiple repos

Default import target: **workstation-environment** (docs/architecture).  
Clone/filter CSV by label `repo::spire-infra` etc. when those repos exist, or import all into a single **lzt-program** GitLab project used as the program board.
