# Agile Import Pack — Jira + GitLab

**Program:** LZT-WWI (Linux Zero Trust Workstation & Workload Identity)

## Contents

| Path | Purpose |
|------|---------|
| [jira/jira-issues.csv](jira/jira-issues.csv) | Jira CSV import (Epics, Stories, Tasks) |
| [jira/IMPORT-JIRA.md](jira/IMPORT-JIRA.md) | Step-by-step Jira import |
| [gitlab/gitlab-issues.csv](gitlab/gitlab-issues.csv) | GitLab issues CSV import |
| [gitlab/IMPORT-GITLAB.md](gitlab/IMPORT-GITLAB.md) | Step-by-step GitLab import |
| [gitlab/labels.md](gitlab/labels.md) | Labels to create first |
| [mapping/jira-gitlab-crosswalk.csv](mapping/jira-gitlab-crosswalk.csv) | Same backlog key in both systems |
| [mapping/link-conventions.md](mapping/link-conventions.md) | How issues reference each other |

## Recommended order

1. Create Jira project (e.g. key `LZT`) and components/labels.
2. Import **Epics** first (filter CSV or import all — epics appear as Issue Type Epic).
3. Import Stories/Tasks (Epic Link column uses epic **Summary** or epic key depending on Jira version — see IMPORT-JIRA.md).
4. Create GitLab project(s); add labels from `labels.md`.
5. Import GitLab issues CSV.
6. In Jira, set remote links / mention GitLab issue URLs (or use GitLab-Jira integration if licensed).
7. In GitLab descriptions, keep `Jira: LZT-nnn` markers from the CSV.

## Single source of truth

- **Delivery status:** Jira  
- **Code & MR:** GitLab  
- **Architecture:** this git repo (`docs/`)

## ID scheme

| Prefix | Meaning |
|--------|---------|
| `LZT-E#` | Epic (logical); becomes Jira epic |
| `LZT-S#` | Story |
| `LZT-T#` | Task/Sub-work |
| `GL-#` | Row id in GitLab import (GitLab assigns IID on import) |

Crosswalk file maps `BacklogKey` → both systems after import (update Jira keys post-import).
