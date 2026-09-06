---
inclusion: manual
---

# OAuth Configuration Fix Process

> **Superseded note:** the domain is now `api.foodshare.club` (not
> `backend.foodshare.club`). Do **not** hand-edit `.env` on the VPS — secrets
> flow from GitHub Actions Secrets → Supabase Vault via `scripts/deploy.sh`
> during CI/CD. Manual SSH is for debugging only.

## The Problem
Error: `{"code": 400,"error_code": "validation_failed","msg": "Unsupported provider: missing OAuth secret"}`

URL: `https://api.foodshare.club/auth/v1/authorize?provider=google`

## Root Cause
OAuth provider secrets are configured in GitHub Actions Secrets but NOT yet
synced into the GoTrue service.

## The Fix (CI/CD only)

1. Ensure the provider secrets exist as GitHub Actions Secrets
   (`GOTRUE_EXTERNAL_GOOGLE_*`, `GOTRUE_EXTERNAL_APPLE_*`, ...).
2. Run the backend deploy pipeline (`backend.yml`) — it maps those secrets into
   the Supabase Vault via `scripts/deploy.sh` and restarts GoTrue with the
   updated env.
3. Verify: `gh run list --limit 3` then retry the authorize URL.

Manual VPS access (debugging only):

```bash
autossh -M 0 -o ServerAliveInterval=6000 -o ServerAliveCountMax=6000 \
  -o ConnectTimeout=10 -o ConnectionAttempts=6000 \
  -i ~/.ssh/foodshare_id_ed25519 organic@api.foodshare.club
```

Audit active secrets with `./scripts/deploy.sh get-secrets`.
