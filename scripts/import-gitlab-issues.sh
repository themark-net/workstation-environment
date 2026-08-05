#!/usr/bin/env bash
# Helper outline: create GitLab issues from CSV using glab (GitLab CLI).
# Prerequisites: glab auth login; project set; labels/milestones exist.
set -euo pipefail
CSV="${1:-docs/project/gitlab/gitlab-issues.csv}"
if ! command -v glab >/dev/null; then
  echo "Install glab: https://gitlab.com/gitlab-org/cli"
  exit 1
fi
# Skip header; naive CSV parse — for production use python.
echo "Prefer GitLab UI CSV import or a Python API script for reliable CSV parsing."
echo "CSV path: $CSV"
echo "Rows: $(($(wc -l < "$CSV") - 1))"
