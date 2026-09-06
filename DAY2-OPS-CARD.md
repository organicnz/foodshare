# Foodshare Quadlet — Day-2 Operations Card
# Quick-reference for production ops after initial deployment

## 📊 Health Checks (run these periodically / in CI)

| Check | Command | Expected |
|---|---|---|
| Web container health | `journalctl --user -u foodshare-web.service --no-pager -n 5` | No ERROR lines, HealthStatus=healthy |
| Cloudflared status | `journalctl --user -u foodshare-cloudflared.service --no-pager -n 5` | Tunnel running, no CRIT errors |
| Web reachable (localhost) | `curl -sf http://127.0.0.1:3000/` | Returns 200 or Next.js page HTML |
| Cloudflared metrics | `curl -sf http://127.0.0.1:2000/metrics` | Returns metrics text (200) |
| End-to-end (HTTPS) | `curl -I https://foodshare.club` | 200 OK, Cloudflare Ray ID visible |
| Network alive | `podman network inspect foodshare` | `Name: foodshare`, Containers listed |

## 🔄 Update Procedure (deliberate, logged)

**App image update** (e.g. new release):
```bash
# 1. CI/CD pushes new digest-referenced image:
#    ghcr.io/foodshareclub/foodshare-web:2026.09.01-sha-abcd1234

# 2. Restart container (pulls new digest if tag changed):
systemctl --user restart foodshare-web.service

# 3. Verify
journalctl --user -u foodshare-web.service -n 10 --no-pager
curl -I https://foodshare.club
```

**Cloudflared update** (official image, low risk):
```bash
systemctl --user restart foodshare-cloudflared.service
# Tunnel target stays in Cloudflare dashboard — no unit change needed
```

## 🚨 Emergency Rollback (at any point)

**Rollback to Docker web container:**
```bash
# 1. Restart Docker compose (instant):
docker compose -f /path/to/foodshare-web/docker-compose.yml up -d

# 2. Redirect cloudflared tunnel back to Docker host:
#    - Delete the `foodshare-web-club` tunnel in Cloudflare dashboard
#    - Recreate it targeting your old Docker host IP/port
#    - Or: just restart cloudflared (it will use the tunnel config stored in CF)
systemctl --user restart foodshare-cloudflared.service

# 3. Verify
curl -I https://foodshare.club  # should return to pre-migration state
```

**Rollback does NOT touch Supabase** — stays running in Docker as always.

## 📝 Log Monitoring (production)

```bash
# Tail web container logs
journalctl --user -u foodshare-web.service -f

# Tail cloudflared logs
journalctl --user -u foodshare-cloudflared.service -f

# Combined view (two panes if possible)
journalctl --user -u foodshare-web.service -f &
journalctl --user -u foodshare-cloudflared.service -f &
wait
```

## 🛠 Common Issues & Fixes

| Symptom | Likely Cause | Fix |
|---|---|---|
| `systemctl --user start foodshare-web.service` hangs / times out | Podman not ready, or network not started | `systemctl --user start foodshare-network.service` first, then web |
| `curl https://foodshare.club` gives 522/524 | Cloudflared tunnel not fully provisioned | `journalctl --user -u foodshare-cloudflared.service -n 20`; wait 1-2 min for CF propagation |
| Web returns 502 at `127.0.0.1:3000` | Next.js not fully started or healthcheck not green | Wait 10-15s; check `journalctl --user -u foodshare-web.service -n 10` |
| `Permission denied` writing env file | File not `chmod 600` or wrong owner | `chmod 600 ~/.config/foodshare/web.env` and `chmod 600 ~/.config/foodshare/cloudflared.env` |
| `podman: failed to start container: ... permission denied` | Rootless mode not enabled / linger not set | `loginctl enable-linger $USER`; reboot or re-login |

## 📦 What Still Runs in Docker (NOT migrated)

These are **intentionally left in Docker** for stability:

- **Supabase stack** (15 services): Postgres, Kong, Auth, Functions, Analytics, etc.
  - Rollback: `docker compose -f /path/to/foodshare-backend/docker-compose.yml up -d`
  - Network: `supabase-network` (bridge — internal DNS names only valid inside Docker)

- **Foodshare runner** (GitHub Actions runners)
  - `foodshare-runner/docker-compose.yml`

- **Do NOT attempt to Quadlet-migrate these in bulk** — too tightly coupled, high risk.

## 🗂 File Inventory (what was deployed)

| File | Path | Purpose |
|---|---|---|
| `foodshare.network` | `~/.config/containers/systemd/foodshare.network` | Quadlet bridge network |
| `foodshare-web.container` | `~/.config/containers/systemd/foodshare-web.container` | Next.js frontend unit |
| `foodshare-web.env` | `~/.config/foodshare/web.env` | Frontend env vars (replace placeholders!) |
| `foodshare-cloudflared.container` | `~/.config/containers/systemd/foodshare-cloudflared.container` | Cloudflare Tunnel unit |
| `foodshare-cloudflared.env` | `~/.config/foodshare/cloudflared.env` | Cloudflare tunnel token (never commit!) |
| `DEPLOY-PRODUCTION.sh` | `./DEPLOY-PRODUCTION.sh` | Full setup + start script (optional) |
| `DOCKER-TO-PODMAN-MIGRATION-PLAN.md` | `./DOCKER-TO-PODMAN-MIGRATION-PLAN.md` | Full migration strategy doc |

---
*Keep this card handy. For the full cutover workflow, migration strategy, and service-by-service Supabase migration notes, see DOCKER-TO-PODMAN-MIGRATION-PLAN.md.*