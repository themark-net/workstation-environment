# Importing into Jira

## Compatible with

Jira Cloud / Data Center **CSV import** (Issues → Import external projects, or System → External system import → CSV).

## Before import

1. Create project **LZT** (Scrum or Kanban).
2. Ensure issue types: **Epic**, **Story**, **Task** exist.
3. Create labels: `linux`, `zero-trust`, `entra`, `intune`, `awx`, `spire`, `pki`, `tpm-cba`, `pilot`.
4. Optional components: `Platform`, `IAM`, `PKI`, `Endpoint`, `Security`, `Docs`.
5. Create empty Epics manually **or** import CSV with Issue Type = Epic first.

## CSV columns used

`Summary`, `Issue Type`, `Description`, `Epic Name`, `Epic Link`, `Priority`, `Labels`, `Story Points`, `Component/s`, `Backlog Key`, `Phase`, `Estimate Hours`

**Note:** Jira may ignore unknown columns; map `Story Points` to your custom field; map `Estimate Hours` to Original Estimate if desired (convert hours → seconds: hours * 3600).

### Epic Link behavior

- On many sites, **Epic Link** must be the Epic’s **Issue Key** after epics exist.
- **Workflow A (two-pass):**
  1. Import rows where `Issue Type` = Epic (Epic Name = Summary).
  2. Note generated keys (LZT-1, …).
  3. Update Story/Task rows’ `Epic Link` column with those keys; re-import stories.
- **Workflow B:** Use a marketplace CSV import that matches Epic Name string.

## After import

1. Replace `Backlog Key` in descriptions is already present as `BacklogKey: LZT-S01` in Description.
2. Fill [mapping/jira-gitlab-crosswalk.csv](../mapping/jira-gitlab-crosswalk.csv) **Jira Key** column.
3. Link GitLab project in Jira Development panel if DVCS/GitLab app enabled.

## Automation (optional)

If you have `jira` CLI or API tokens, bulk-create from CSV with a script; the CSV remains the portable artifact for PMO.
