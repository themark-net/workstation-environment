# Jira ↔ GitLab Link Conventions

## Identifiers

- **BacklogKey** (stable): `LZT-E1`, `LZT-S01`, `LZT-T01` — never changes; in both systems’ descriptions.
- **Jira Key** (after import): `LZT-42` — fill crosswalk.
- **GitLab IID** (after import): `#17` in project — fill crosswalk.

## Description footer (required on all issues)

```text
---
BacklogKey: LZT-S01
Jira: LZT-XX
GitLab: group/project#IID
Architecture: https://github.com/themark-net/workstation-environment (or GitLab mirror URL)
```

## MR convention

```text
LZT-42: short title

Implements BacklogKey LZT-S01 / GitLab #17
```

## Do not

- Duplicate epics as separate product backlogs without crosswalk update.
- Close Jira while GitLab remains open without sync note.
