#!/usr/bin/env bash
# Set the Salesforce org secrets for one environment.
# Run once per environment (qa / uat / preprod / production) with that env's org values.
#
# Usage:
#   bash scripts/github/set-org-secrets.sh <environment> <consumer_key> <username> <path-to-server.key>
#
# Example:
#   bash scripts/github/set-org-secrets.sh qa 3MVG9abc... deployer@acme.com.qa ~/keys/server.key
set -euo pipefail

ENVIRONMENT="${1:?environment required (qa|uat|preprod|production)}"
CONSUMER_KEY="${2:?consumer key (client id) required}"
USERNAME="${3:?integration username required}"
KEY_FILE="${4:?path to server.key (JWT private key) required}"

REPO_NAME="Salesforce-Learning-Projects-Rep"
OWNER="$(gh api user --jq .login)"
REPO="${OWNER}/${REPO_NAME}"

[ -f "${KEY_FILE}" ] || { echo "Key file not found: ${KEY_FILE}" >&2; exit 1; }

echo "==> Setting org secrets for environment '${ENVIRONMENT}' on ${REPO}"
gh secret set SF_CONSUMER_KEY   --env "${ENVIRONMENT}" --repo "${REPO}" --body "${CONSUMER_KEY}"
gh secret set SF_USERNAME       --env "${ENVIRONMENT}" --repo "${REPO}" --body "${USERNAME}"
gh secret set SF_JWT_SERVER_KEY --env "${ENVIRONMENT}" --repo "${REPO}" < "${KEY_FILE}"

echo "==> Done. Secrets set for '${ENVIRONMENT}': SF_CONSUMER_KEY, SF_USERNAME, SF_JWT_SERVER_KEY"
echo "    (SF_INSTANCE_URL was seeded during provisioning.)"
