# Foodshare

Meta-repo pinning the five Foodshareclub projects and the production
deployment layer (Quadlet units, CI/CD). Docs live in their repos —
this root stays minimal.

## Projects

| Directory | Repo | Description |
|---|---|---|
| `foodshare-app/` | Foodshareclub/foodshare-app | iOS / Android (Skip) app — incl. `docs/swift-kotlin-rules.md` |
| `foodshare-backend/` | Foodshareclub/foodshare-backend | Self-hosted Supabase + edge functions |
| `foodshare-web/` | Foodshareclub/foodshare-web | Next.js frontend — incl. `docs/PHASAL-PLAN.md`, `.env.*.sentry` |
| `foodshare-tools/` | Foodshareclub/foodshare-tools | CLI, simulator, build tooling |
| `foodshare-runner/` | Foodshareclub/foodshare-runner | Self-hosted CI runners (VPS) — incl. `docs/` (Quadlet migration plan, Day-2 ops card) and `scripts/DEPLOY-PRODUCTION.sh` |

## Deployment layer

- `.config/containers/systemd/` — Podman Quadlet units (`foodshare-web`,
  `foodshare-cloudflared`, network)
- `.config/foodshare/` — environment file templates (`chmod 600` on the VPS)
- `.github/workflows/` — root CI (per-domain gates + infra validation),
  staging CD, Quadlet apply, releases
