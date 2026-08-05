# Agile Imports — Jira + GitLab

## Contents

| Path | Purpose |
|------|---------|
| [jira/ltz-jira-import.csv](jira/ltz-jira-import.csv) | Epics + Stories + Sub-tasks for Jira CSV import |
| [jira/ltz-jira-epics-stories.csv](jira/ltz-jira-epics-stories.csv) | Epics + Stories only (simpler) |
| [jira/ltz-hour-estimates.csv](jira/ltz-hour-estimates.csv) | Hours ≈ StoryPoints × 4 for PM tools |
| [gitlab/ltz-gitlab-issues.csv](gitlab/ltz-gitlab-issues.csv) | GitLab issue import CSV |
| [mapping/TRACEABILITY.md](mapping/TRACEABILITY.md) | Key map |
| [mapping/jira-gitlab-map.json](mapping/jira-gitlab-map.json) | Machine-readable map |

## Jira import steps

1. Create Jira project **LTZ** (Scrum or Kanban).  
2. Ensure **Epic** issue type and **Story Points** field exist (company-managed: add if needed).  
3. **Settings → System → External System Import → CSV** (admin), or project import CSV if available.  
4. Map columns:
   - Issue Type → Issue Type  
   - Summary → Summary  
   - Description → Description  
   - Epic Name → Epic Name (epics)  
   - Epic Link / Epic Name → Epic Link for stories (product-dependent)  
   - Parent → Parent for sub-tasks  
   - Labels → Labels  
   - Story Points → Story Points  
   - External ID → optional external id  
5. Import **epics first** if your Jira requires epics to exist before Epic Link (split CSV if needed).  
6. After import, bulk-edit stories to set **Epic Link** if CSV mapping failed.

### If Epic Link fails

Use `ltz-jira-epics-stories.csv`, import epics, then stories with **Epic Name** matching. Manually link or use Automation.

## GitLab import steps

1. Create group `linux-zero-trust` (or org equivalent).  
2. Create project e.g. `ltz-delivery` (issue tracker) **or** import into `zt-awx-config`.  
3. Create milestones: `LTZ Phase 0`, `LTZ Phase 1`, `LTZ Phase 1b`, `LTZ Phase 2`, `LTZ Phase 3`, `LTZ Phase X`.  
4. **Plan → Issues → Import** (CSV) — see [GitLab CSV import](https://docs.gitlab.com/ee/user/project/import/csv.html).  
5. Map: title, description, labels, weight, milestone.  
6. Create labels used in CSV (`ltz`, `epic`, `story`, `task`, `phase-*`, epic keys).

## Linking convention (gold standard)

| System | Convention |
|--------|------------|
| Jira summary | `[LTZ-S013] TPM PKCS#11 Entra CBA enrollment path` |
| GitLab title | **Identical** summary string |
| Jira description | Contains `GitLab:` URL after issue exists |
| GitLab description | Contains `Jira Story: LTZ-S013` and browse URL |
| MRs | `Closes #N` / `LTZ-S013` in commit message |
| Repos | Code in zt-awx-config / zt-spire-config; docs in workstation-environment |

### After both imports

Run a quick script or manual pass:

1. Export Jira issue keys + External ID.  
2. Paste Jira browse links into matching GitLab issues.  
3. Paste GitLab URLs into Jira descriptions or remote links.

## Story points ↔ hours

**1 SP ≈ 4 man-hours** in this program (see COST_ESTIMATES.md). Adjust if org standard differs; keep ratio consistent in reporting.
