# Salesforce DX → GitHub Actions CI/CD — Setup Guide

CI/CD for **Salesforce Learning Projects Rep** with a promotion pipeline across four
protected branches. Authentication uses the **OAuth 2.0 Client Credentials flow**
(server-to-server; runs as a configured "Run As" user — no passwords, no JWT key).
Deployments are **delta-only** (via `sfdx-git-delta`).

## Branch & environment model

| Branch    | GitHub Environment | Target org        |
| --------- | ------------------ | ----------------- |
| `qa`      | `qa`               | QA sandbox / org  |
| `uat`     | `uat`              | UAT sandbox / org |
| `preprod` | `preprod`          | Pre-Prod sandbox  |
| `main`    | `production`       | Production        |

Promotion flow: `feature/*` → **PR into `qa`** → `qa` → **PR into `uat`** → `uat` →
**PR into `preprod`** → `preprod` → **PR into `main`**.

> All four environments currently point at the **same Developer org** via their own
> secrets. To target different orgs later, just update that environment's secrets.

## What the pipeline enforces (branch protection)

Applied as a repository **ruleset** (`.github/rulesets/protect-release-branches.json`)
to `main`, `preprod`, `uat`, and `qa`:

- 🚫 **No direct commits** — every change must go through a Pull Request.
- ✅ **Validation build must pass before merge** — the `Check-only Validation` and
  `Lint, Format & Jest` status checks are required and must be green.
- 👤 **Reviewer approval required before merge** — at least **1** approving review;
  stale approvals are dismissed when new commits are pushed.
- 🔒 No force-pushes, no branch deletion. No bypass actors (applies to everyone).

Enforced order: open PR → CI validates (check-only, nothing deployed) → reviewer
approves → **only then** can it be merged. On merge, `Deploy` deploys the delta to
that branch's org.

## Authentication — Client Credentials flow

The pipeline authenticates by POSTing to the org's token endpoint:

```
POST https://<MyDomain>/services/oauth2/token
  grant_type=client_credentials
  client_id=<SF_CLIENT_ID>
  client_secret=<SF_CLIENT_SECRET>
```

…then logs the Salesforce CLI in with the returned access token
(`sf org login access-token`). See `.github/actions/setup-sfdx/action.yml`.

### Per-environment secrets

| Secret             | Value                                                        |
| ------------------ | ------------------------------------------------------------ |
| `SF_CLIENT_ID`     | External Client App **Consumer Key**                         |
| `SF_CLIENT_SECRET` | External Client App **Consumer Secret**                      |
| `SF_INSTANCE_URL`  | Org **My Domain** URL (e.g. `https://xxx.my.salesforce.com`) |

> ⚠️ `SF_INSTANCE_URL` **must** be the org My Domain — Client Credentials does **not**
> work against `login.salesforce.com` / `test.salesforce.com`.

---

## One-time setup

### Prerequisites

- **Git**, **Node.js 20+**, **Salesforce CLI** (`npm i -g @salesforce/cli`)
- **GitHub CLI** (`gh`) authenticated
- Admin access to each target org

### Step 1 — Provision GitHub (repo, branches, environments, protection)

```bash
bash scripts/github/provision-github.sh
```

Creates the repo, pushes `main/preprod/uat/qa`, creates the four environments, and
applies the ruleset.

### Step 2 — Configure the External Client App (Salesforce)

In each target org:

1. **My Domain deployed** — Setup → My Domain → _Deployed to Users_. Copy the URL.
2. **External Client App / Connected App** → enable OAuth. Scopes must include
   `Manage user data via APIs (api)` and `Perform requests at any time
(refresh_token, offline_access)`.
3. **Enable Client Credentials Flow** on the app.
4. **Run As user** — App Manager → app → Manage → Edit Policies → _Client Credentials
   Flow_ → set **Run As** to an integration/admin user with **API Enabled**.
5. **Relax IP restrictions** (CI runners have changing IPs). Save; wait ~2–10 min.
6. Copy the **Consumer Key** and **Consumer Secret**.

### Step 3 — Set the secrets per environment

```bash
bash scripts/github/set-org-secrets.sh qa        <CLIENT_ID> <CLIENT_SECRET> https://<MyDomain>
bash scripts/github/set-org-secrets.sh uat       <CLIENT_ID> <CLIENT_SECRET> https://<MyDomain>
bash scripts/github/set-org-secrets.sh preprod   <CLIENT_ID> <CLIENT_SECRET> https://<MyDomain>
bash scripts/github/set-org-secrets.sh production <CLIENT_ID> <CLIENT_SECRET> https://<MyDomain>
```

### Step 4 — Verify auth locally (optional but recommended)

```bash
curl -s -X POST "https://<MyDomain>/services/oauth2/token" \
  --data-urlencode "grant_type=client_credentials" \
  --data-urlencode "client_id=<CLIENT_ID>" \
  --data-urlencode "client_secret=<CLIENT_SECRET>"
# Expect JSON with an access_token and instance_url.
```

### Step 5 — End-to-end

```bash
git checkout -b feature/ci-smoke-test qa
# make a tiny change under force-app/
git commit -am "test: trigger CI" && git push -u origin feature/ci-smoke-test
```

Open a PR into `qa`. The validation build runs; the PR cannot merge until it passes
**and** a reviewer approves. Merge → the `Deploy` workflow runs.

---

## ⚠️ Solo-repo note about the approval requirement

GitHub does not let you approve your **own** PR. With "1 approving review" required and
no other collaborator, you cannot merge your own PRs. This repo has a collaborator
(`SourabhBaloniSW`) invited as reviewer. Alternatively, temporarily add yourself as a
bypass actor on the ruleset (Settings → Rules) for solo work.

---

## Reference — files

| File                                             | Purpose                                            |
| ------------------------------------------------ | -------------------------------------------------- |
| `.github/actions/setup-sfdx/action.yml`          | Setup: Node, SF CLI, `sfdx-git-delta`, CC auth     |
| `.github/workflows/pr-validation.yml`            | PR → quality gates + check-only validation         |
| `.github/workflows/deploy.yml`                   | Push to a protected branch → delta deploy          |
| `.github/rulesets/protect-release-branches.json` | Branch-protection ruleset (all 4 branches)         |
| `scripts/github/provision-github.sh`             | Create repo/branches/environments + apply ruleset  |
| `scripts/github/set-org-secrets.sh`              | Set Client Credentials secrets for one environment |
