# Foodshare

Meta-repo pinning the five Foodshareclub projects and the production
deployment layer (Quadlet units, CI/CD, Sentry, migration docs).

## Projects

| Directory | Repo | Description |
|---|---|---|
| `foodshare-app/` | Foodshareclub/foodshare-app | iOS / Android (Skip) app |
| `foodshare-backend/` | Foodshareclub/foodshare-backend | Self-hosted Supabase + edge functions |
| `foodshare-web/` | Foodshareclub/foodshare-web | Next.js frontend |
| `foodshare-tools/` | Foodshareclub/foodshare-tools | CLI, simulator, build tooling |
| `foodshare-runner/` | Foodshareclub/foodshare-runner | Self-hosted CI runners (VPS) |

Each project has its own repo, CI, and `docs/` — this root only tracks the
pins (`.gitmodules`), the deployment layer, and cross-cutting plans.

## Deployment layer

- `.config/containers/systemd/` — Podman Quadlet units (`foodshare-web`,
  `foodshare-cloudflared`, network)
- `.config/foodshare/` — environment file templates (`chmod 600` on the VPS)
- `.github/workflows/` — root CI (per-domain gates + infra validation),
  staging CD, Quadlet apply, releases
- `docs/DEPLOY-PRODUCTION.sh` — VPS bringup (Quadlet sync + start + verify)
- `docs/.env.production.sentry` / `docs/.env.example.sentry` — Sentry config

## Docs

- `docs/DOCKER-TO-PODMAN-MIGRATION-PLAN.md` — Docker → Quadlet cutover plan
- `docs/MIGRATION-PHASAL-PLAN.md` — 10x pro phasal plan (infra + code)
- `docs/PHASAL-PLAN.md` — incremental modernization phases
- `docs/DAY2-OPS-CARD.md` — day-2 operations quick reference
