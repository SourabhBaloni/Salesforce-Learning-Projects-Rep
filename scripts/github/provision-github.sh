#!/usr/bin/env bash
# Provision the GitHub repo, branches, environments, and branch-protection ruleset
# for the Salesforce Learning Projects Rep CI/CD pipeline.
#
# Requires: gh (authenticated via `gh auth login`), git.
# Run from the repo root:  bash scripts/github/provision-github.sh
set -euo pipefail

REPO_NAME="Salesforce-Learning-Projects-Rep"
VISIBILITY="private"                       # private | public
BRANCHES=("main" "preprod" "uat" "qa")
ENVIRONMENTS=("qa" "uat" "preprod" "production")

OWNER="$(gh api user --jq .login)"
echo "==> GitHub user: ${OWNER}"

# 1) Create the repo (skip if it already exists) and push all branches.
if gh repo view "${OWNER}/${REPO_NAME}" >/dev/null 2>&1; then
  echo "==> Repo ${OWNER}/${REPO_NAME} already exists — skipping create."
else
  echo "==> Creating ${VISIBILITY} repo ${OWNER}/${REPO_NAME} ..."
  gh repo create "${REPO_NAME}" --"${VISIBILITY}" --source . --remote origin --push
fi

# 2) Ensure the four branches exist on the remote (created locally, then pushed).
for b in "${BRANCHES[@]}"; do
  if ! git show-ref --verify --quiet "refs/heads/${b}"; then
    git branch "${b}" main 2>/dev/null || true
  fi
  git push -u origin "${b}"
done

# Set main as the default branch.
gh repo edit "${OWNER}/${REPO_NAME}" --default-branch main

# 3) Create deployment environments (idempotent).
for e in "${ENVIRONMENTS[@]}"; do
  echo "==> Ensuring environment: ${e}"
  gh api -X PUT "repos/${OWNER}/${REPO_NAME}/environments/${e}" >/dev/null
done

# 4) Org secrets (SF_CLIENT_ID, SF_CLIENT_SECRET, SF_INSTANCE_URL) are added per
#    environment later via scripts/github/set-org-secrets.sh — SF_INSTANCE_URL must be
#    the org My Domain (Client Credentials does not work against login/test hosts).

# 5) Apply the branch-protection ruleset (no direct commits, required checks, required review).
echo "==> Applying branch-protection ruleset ..."
gh api -X POST "repos/${OWNER}/${REPO_NAME}/rulesets" \
  --input .github/rulesets/protect-release-branches.json >/dev/null \
  && echo "    Ruleset created." \
  || echo "    Ruleset POST failed (it may already exist — check repo Settings > Rules)."

echo ""
echo "==> Done. Repo: https://github.com/${OWNER}/${REPO_NAME}"
echo "    Branches: ${BRANCHES[*]}"
echo "    Environments: ${ENVIRONMENTS[*]}"
echo "    Next: add org secrets with scripts/github/set-org-secrets.sh once you have the Connected App creds."
