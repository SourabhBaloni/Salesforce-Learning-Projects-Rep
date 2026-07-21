#!/usr/bin/env bash
# Set the Salesforce Client Credentials secrets for one environment.
# Run once per environment (qa / uat / preprod / production) with that env's org values.
#
# Usage:
#   bash scripts/github/set-org-secrets.sh <environment> <client_id> <client_secret> <my_domain_url>
#
# Example:
#   bash scripts/github/set-org-secrets.sh qa 3MVG9abc... 080FCB... https://mydomain.my.salesforce.com
#
# Notes:
#   - Client Credentials flow authenticates as the "Run As" user configured ON the
#     External Client App in Salesforce. No username/JWT key is needed.
#   - my_domain_url must be the org My Domain (NOT login/test.salesforce.com).
set -euo pipefail

ENVIRONMENT="${1:?environment required (qa|uat|preprod|production)}"
CLIENT_ID="${2:?client_id (Consumer Key) required}"
CLIENT_SECRET="${3:?client_secret (Consumer Secret) required}"
INSTANCE_URL="${4:?My Domain URL required}"

REPO_NAME="Salesforce-Learning-Projects-Rep"
OWNER="$(gh api user --jq .login)"
REPO="${OWNER}/${REPO_NAME}"

echo "==> Setting Client Credentials secrets for environment '${ENVIRONMENT}' on ${REPO}"
printf '%s' "${CLIENT_ID}"     | gh secret set SF_CLIENT_ID     --env "${ENVIRONMENT}" --repo "${REPO}"
printf '%s' "${CLIENT_SECRET}" | gh secret set SF_CLIENT_SECRET --env "${ENVIRONMENT}" --repo "${REPO}"
printf '%s' "${INSTANCE_URL}"  | gh secret set SF_INSTANCE_URL  --env "${ENVIRONMENT}" --repo "${REPO}"

echo "==> Done. Secrets set for '${ENVIRONMENT}': SF_CLIENT_ID, SF_CLIENT_SECRET, SF_INSTANCE_URL"
