# Salesforce DX → GitHub Actions CI/CD — Setup Guide

CI/CD for **Salesforce Learning Projects Rep** with a promotion pipeline across four
protected branches. Authentication uses the **JWT Bearer flow** (no passwords stored)
and deployments are **delta-only** (via `sfdx-git-delta`).

## Branch & environment model

| Branch    | GitHub Environment | Target org        | Login URL                     |
| --------- | ------------------ | ----------------- | ----------------------------- |
| `qa`      | `qa`               | QA sandbox        | https://test.salesforce.com   |
| `uat`     | `uat`              | UAT sandbox       | https://test.salesforce.com   |
| `preprod` | `preprod`          | Pre-Prod sandbox  | https://test.salesforce.com   |
| `main`    | `production`       | Production        | https://login.salesforce.com  |

Promotion flow: `feature/*` → **PR into `qa`** → `qa` → **PR into `uat`** → `uat` →
**PR into `preprod`** → `preprod` → **PR into `main`**.

> All four branches point at the **same org** until you provide separate org
> credentials per environment. Each environment has its own secrets, so pointing
> them at different orgs later is just a matter of updating that environment's secrets.

## What the pipeline enforces (branch protection)

Applied as a repository **ruleset** (`.github/rulesets/protect-release-branches.json`)
to `main`, `preprod`, `uat`, and `qa`:

- 🚫 **No direct commits** — every change must go through a Pull Request.
- ✅ **Validation build must pass before merge** — the `Check-only Validation` and
  `Lint, Format & Jest` status checks are required and must be green.
- 👤 **Reviewer approval required before merge** — at least **1** approving review;
  stale approvals are dismissed when new commits are pushed.
- 🔒 No force-pushes, no branch deletion.

So the enforced order is: open PR → CI validates (check-only, nothing deployed) →
reviewer approves → **only then** can it be merged. On merge, the `Deploy` workflow
deploys the delta to that branch's org.

---

## One-time setup

### Prerequisites

- **Git**, **Node.js 20+**, **Salesforce CLI** (`npm i -g @salesforce/cli`), **OpenSSL**
- **GitHub CLI** (`gh`) authenticated: `gh auth login`
- Admin access to each target org

### Step 1 — Provision GitHub (repo, branches, environments, protection)

From the repo root, after `gh auth login`:

```bash
bash scripts/github/provision-github.sh
```

This creates the private repo, pushes `main/preprod/uat/qa`, creates the four
environments, seeds `SF_INSTANCE_URL` per environment, and applies the ruleset.

### Step 2 — Create the JWT key pair (one time)

In a temp folder **outside the repo**:

```bash
openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 \
  -keyout server.key -out server.crt -subj "/CN=SalesforceCI"
```

`server.key` = private (→ GitHub secret). `server.crt` = public (→ uploaded to the org).
**Never commit `server.key`.**

### Step 3 — Create a Connected App in each org

Setup → App Manager → New Connected App → Enable OAuth Settings →
Callback URL `http://localhost:1717/OauthRedirect` → **Use digital signatures** (upload
`server.crt`) → scopes: `api`, `refresh_token offline_access`, (optional `full`) → Save.
Wait ~10 min. Then copy the **Consumer Key** and pre-authorize your integration user
(Manage → Edit Policies → *Admin approved users are pre-authorized* → add its profile/perm set).

> The org **Client Id (Consumer Key)** and **Client Secret** you will provide map to
> `SF_CONSUMER_KEY`. JWT auth uses the Consumer Key + private key; the secret is not
> needed for JWT but keep it safe.

### Step 4 — Add the org secrets per environment

For each environment, with that org's values:

```bash
bash scripts/github/set-org-secrets.sh qa      <CONSUMER_KEY> <USERNAME> /path/to/server.key
bash scripts/github/set-org-secrets.sh uat     <CONSUMER_KEY> <USERNAME> /path/to/server.key
bash scripts/github/set-org-secrets.sh preprod <CONSUMER_KEY> <USERNAME> /path/to/server.key
bash scripts/github/set-org-secrets.sh production <CONSUMER_KEY> <USERNAME> /path/to/server.key
```

Each environment ends up with: `SF_CONSUMER_KEY`, `SF_USERNAME`, `SF_JWT_SERVER_KEY`,
`SF_INSTANCE_URL`.

### Step 5 — Verify

```bash
git checkout -b feature/ci-smoke-test qa
# make a tiny change under force-app/
git commit -am "test: trigger CI" && git push -u origin feature/ci-smoke-test
```

Open a PR into `qa`. Confirm: the validation build runs, the PR is **not mergeable**
until it passes and a reviewer approves. Merge → the `Deploy` workflow runs.

---

## ⚠️ Solo-repo note about the approval requirement

GitHub does **not** let you approve your own Pull Request. With "1 approving review"
required and no other collaborator, you will be unable to merge your own PRs. Options:

1. **Add a collaborator/reviewer** to the repo (recommended — matches the intended flow).
2. Temporarily add yourself as a **bypass actor** on the ruleset (Settings → Rules) for
   solo learning, then remove it when a reviewer is available.

The ruleset ships with **no bypass actors** (strict), exactly as requested.

---

## Reference — files

| File                                         | Purpose                                             |
| -------------------------------------------- | --------------------------------------------------- |
| `.github/actions/setup-sfdx/action.yml`      | Shared setup: Node, SF CLI, `sfdx-git-delta`, JWT   |
| `.github/workflows/pr-validation.yml`        | PR → quality gates + check-only validation          |
| `.github/workflows/deploy.yml`               | Push to a protected branch → delta deploy           |
| `.github/rulesets/protect-release-branches.json` | Branch-protection ruleset (all 4 branches)      |
| `scripts/github/provision-github.sh`         | Create repo/branches/environments + apply ruleset   |
| `scripts/github/set-org-secrets.sh`          | Set org secrets for one environment                 |
