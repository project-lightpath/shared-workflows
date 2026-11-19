#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ! ${1:-} =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "Usage: $0 OWNER/REPO" >&2
  exit 2
fi

repo=$1
branch=$(gh api "repos/$repo" --jq '.default_branch | @uri')
protected=$(gh api "repos/$repo/branches/$branch" --jq '.protected')
if [ "$protected" != "false" ]; then
  echo "Branch already protected; review its existing settings instead." >&2
  exit 1
fi

gh api --method PUT "repos/$repo/branches/$branch/protection" --input - <<'JSON'
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "require_code_owner_reviews": true,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
