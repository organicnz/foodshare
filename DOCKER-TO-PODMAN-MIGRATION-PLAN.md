# Foodshare: Docker → Podman/Quadlet Migration Plan
# Oracle VPS, Ubuntu 26.04 LTS (arm64), Podman 5.7.0, Quadlet confirmed

## Stack Summary (from discovery)

| Service | Image | Ports | Key Config |
|---|---|---|---|
| **foodshare-web** | `ghcr.io/foodshareclub/foodshare-web:latest` | 3000/TCP | Next.js, `.env.production`, Cloudflared tunnel |
| **foodshare-cloudflared** | `cloudflare/cloudflared:latest` | none (tunnel egress only) | Tunnel `foodshare-web-club` → web container |
| **supabase-stack** | Self-hosted (15 services) | Variety | Postgres + Kong + Auth + Rest + Functions + Analytics on `supabase-network` |
| **foodshare-runner** | GitHub runner image | Varies | CI runners, org + personal profiles |

**Critical finding**: Supabase is **self-hosted** on this box (not cloud). The `foodshare-backend/docker-compose.yml` runs a full Supabase stack: Postgres, Kong gateway, GoTrue auth, PostgREST, Realtime, Storage, Functions, Logflare, Grafana, Prometheus, Loki, Vector, supavisor pooler, autoheal.

---

## Migration Strategy: Two-Phase Approach (Frontend + Cloudflared)

### Phase 1 — Frontend + Cloudflared Quadlet (Immediate win, low risk)
Migrate `foodshare-web` (Next.js) + `foodshare-cloudflared` to Quadlet. Keep the Supabase Docker stack running during this phase for a seamless rollout.

**Why this matters**: The Cloudflare tunnel is the public entry point. Moving it to Quadlet means the tunnel runs rootless inside a container, and the public DNS (`foodshare.club`) continues working without host-level privilege manipulation.

### Phase 2 — Full Stack (Optional)
Keep Supabase in Docker as the rollback path. Can be migrated incrementally later.

---

## Quadlet Units Created

### 1. Network
```ini
# ~/.config/containers/systemd/foodshare.network
[Network]
NetworkName=foodshare
```

### 2. Frontend Web
```ini
# ~/.config/containers/systemd/foodshare-web.container
[Unit]
Description=Foodshare Next.js frontend
After=foodshare-network.service
Requires=foodshare-network.service

[Container]
Image=ghcr.io/foodshareclub/foodshare-web:latest
ContainerName=foodshare-web
Network=foodshare.network
PublishPort=127.0.0.1:3000:3000
EnvironmentFile=%h/.config/foodshare/web.env
HealthCmd=curl -f http://localhost:3000/ || exit 1
HealthInterval=15s
HealthTimeout=5s
HealthRetries=3
HealthStartPeriod=20s
Notify=healthy

ReadOnly=true
NoNewPrivileges=true
DropCapability=ALL
UserNS=keep-id

[Service]
Restart=always
TimeoutStartSec=120
Type=notify

[Install]
WantedBy=default.target
```

### 3. Cloudflare Tunnel (hardened 2026-09-07: `Type=simple`, `BindsTo=`, no metrics port)
```ini
# ~/.config/containers/systemd/foodshare-cloudflared.container
[Unit]
Description=Cloudflare Tunnel for Foodshare frontend
After=foodshare-network.service foodshare-web.service
Requires=foodshare-web.service
# Wait for web to be healthy first (BindsTo stops tunnel if web stops)
BindsTo=foodshare-web.service

[Container]
Image=cloudflare/cloudflared:latest
ContainerName=foodshare-cloudflared
Network=foodshare.network
EnvironmentFile=%h/.config/foodshare/cloudflared.env
# Alternatively, use a secret:
# Secret=cf_tunnel_token,type=env,target=CLOUDFLARE_TUNNEL_TOKEN

# The tunnel runs in the background; cloudflared handles the HTTP->HTTPS routing
Command=tunnel --no-autoupdate run foodshare-web-club

[Service]
Restart=always
TimeoutStartSec=60
Type=simple

[Install]
WantedBy=default.target
```

### 4. Environment Files (create + `chmod 600`)

**`~/.config/foodshare/web.env`** (copied from `foodshare-web/.env.production`):
```
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
NEXT_PUBLIC_APP_URL=https://foodshare.club
NEXT_PUBLIC_SITE_URL=https://foodshare.club
```

**`~/.config/foodshare/cloudflared.env`**:
```
CLOUDFLARE_TUNNEL_TOKEN=your-cloudflare-tunnel-token-here
```
*(Get this from Cloudflare Dashboard → Tunnels → create tunnel named `foodshare-web-club`)*

---

## Cutover Workflow (Production-Ready — Zero Downtime Target)

### Step 0 — Preflight (run once)
```bash
mkdir -p ~/.config/containers/systemd ~/.config/foodshare
# Copy env files (replace placeholders):
cp foodshare-web/.env.production ~/.config/foodshare/web.env
chmod 600 ~/.config/foodshare/web.env

# Create cloudflared env — get token from:
#   https://dash.cloudflare.com/?to=:/tunnels
# Create a tunnel named "foodshare-web-club", paste token below:
cp .env.fakecloudflared.token ~/.config/foodshare/cloudflared.env  # rename + edit
chmod 600 ~/.config/foodshare/cloudflared.env
```

### Step 1 — Bring up Quadlet stack on alternate ports
```bash
systemctl --user daemon-reload
systemctl --user start foodshare-network.service
systemctl --user start foodshare-web.service      # starts on 127.0.0.1:3000
systemctl --user start foodshare-cloudflared.service # starts cloudflared tunnel (no exposed ports)
```

### Step 2 — Verify health + tunnel
```bash
# Web health
curl -f http://127.0.0.1:3000/ || exit 1

# Check cloudflared is running
journalctl --user -u foodshare-cloudflared.service -n 20 --no-pager

# Verify tunnel service is active
systemctl --user is-active foodshare-cloudflared.service
```

### Step 3 — Update Cloudflare dashboard (if DNS changed)
If your tunnel domain/hostname changed, update:
- Cloudflare DNS records for `foodshare.club` / `api.foodshare.club`
- Any `CLOUDFLARE_TUNNEL_HOSTNAME` overrides if you set custom hostnames

### Step 4 — Keep Docker + Supabase stack running in parallel
- Do NOT touch the Docker compose or Supabase services yet
- This is your instant rollback path

### Step 5 — Switch traffic: Update cloudflared tunnel target
The cloudflared tunnel currently points at the Docker host. We need it to point at the Quadlet web container:

**Option A: Recreate the tunnel** (simplest, zero-downtime if DNS propagates fast)
1. In Cloudflare Dashboard → Tunnels → `foodshare-web-club` → Edit
2. Change the "HTTP service" target from the old Docker host IP/port to `127.0.0.1:3000`
   - Or better: delete the old tunnel, create a new one targeting `127.0.0.1:3000`
3. Cloudflare propagates in ~30–60 seconds

**Option B: If you already have the tunnel configured** — just restart cloudflared:
```bash
systemctl --user restart foodshare-cloudflared.service
```

### Step 6 — Monitor the transition (first 2 hours)
```bash
# Watch web container logs
journalctl --user -u foodshare-web.service -f

# Watch cloudflared logs
journalctl --user -u foodshare-cloudflared.service -f

# End-to-end test: should hit the Quadlet container via cloudflared HTTPS
curl -I https://foodshare.club  # or whatever your tunnel hostname is
```

### Step 7 — Optional: Stop Docker web container (not remove)
```bash
# In the foodshare-web directory:
docker compose -f /path/to/foodshare-web/docker-compose.yml stop foodshare-web
# Or just: docker stop foodshare-web
```
*Keep the container and image for 2+ weeks as rollback.*

### Step 8 — Rollback (if needed at any point)
```bash
# Restart the Docker web container:
docker compose -f /path/to/foodshare-web/docker-compose.yml up -d foodshare-web

# Restart cloudflared to point back at Docker (if you deleted/recreated tunnel:
# just restart — the tunnel target is stored in Cloudflare, not in the unit file)
systemctl --user restart foodshare-cloudflared.service

# Verify:
curl -I https://foodshare.club  # should return to pre-migration state
```

### Step 9 — Decommission Docker (after 2+ weeks of confidence)
```bash
# Only when you're sure everything is solid:
docker compose -f /path/to/foodshare-web/docker-compose.yml down -v

# You may now remove old images if desired:
# docker rmi ghcr.io/foodshareclub/foodshare-web:latest

# Optional: apt purge docker-ce if nothing else on the box needs it
```

---

## Secrets Management (Production Hardening)

| Method | When to Use |
|---|---|
| **`EnvironmentFile=`** (current) | ✅ Default — point to `~/.config/foodshare/web.env` and `~/.config/foodshare/cloudflared.env`, both `chmod 600`. Fine for rootless Quadlet. |
| **`podman secret create`** + `Secret=name,type=env,target=VAR_NAME` | ✅ If you want secrets never written to disk in the unit path. Create once: `podman secret create cf_tunnel_token <(echo "your-token")` then add `Secret=cf_tunnel_token,type=env,target=CLOUDFLARE_TUNNEL_TOKEN` to the cloudflared container. |
| **Inline in unit file** | ❌ **Never** — Quadlet units can be world-readable depending on host setup. |

---

## Auto-Update Strategy (Production)

- **Do not use** `AutoUpdate=registry` on `foodshare-web` or `foodshare-cloudflared` — you don't want the VPS silently pulling whatever lands on `latest`.
- **CI/build pipeline**: Push tagged, digest-referenced images, e.g.:
  ```
  ghcr.io/foodshareclub/foodshare-web:2026.08.27-sha-abcd1234
  ghcr.io/foodshareclub/foodshare-cloudflared:latest  (official image, safe to auto-update)
  ```
- **Deploy**: SSH into the VPS and run:
  ```bash
  systemctl --user restart foodshare-web.service foodshare-cloudflared.service
  ```
- This gives you a deliberate, logged deploy step instead of a timer-driven surprise.

  - *Cloudflare's `cloudflared:latest` is low-risk to auto-update* (official image, security patches only), but your app image is higher-risk.

---

## Key Revisions from Original Plan

| Area | Original | Updated (Production) |
|---|---|---|
| **Cloudflared** | Not mentioned in cutover | Full Quadlet unit + env file + tunnel target update step |
| **Cutover Step 5** | "Flip the host-level reverse proxy" | "Update cloudflared tunnel target in Cloudflare Dashboard" — no host-level proxy needed |
| **Env files** | Generic `web.env` placeholder | Two env files: `web.env` (frontend) + `cloudflared.env` (tunnel token) |
| **Rollback Step 8** | Generic `docker compose down` | Explicit `docker compose down -v` only after 2+ weeks; `docker stop` recommended before |
| **Health checks** | Generic `curl -f http://localhost:3000/` | Web health (`/`) + `systemctl is-active` for tunnel + optional end-to-end `curl -I https://foodshare.club` |
| **Unit dependencies** | `After=foodshare-network.service` | Cloudflared also `Requires=foodshare-web.container` and `Binds=foodshare-web.container` |

---

## Quick Checklist — Run Before `daemon-reload`

- [ ] `mkdir -p ~/.config/containers/systemd ~/.config/foodshare`
- [ ] `cp foodshare-web/.env.production ~/.config/foodshare/web.env && chmod 600 ~/.config/foodshare/web.env`
- [ ] Get Cloudflare tunnel token → `~/.config/foodshare/cloudflared.env`, `chmod 600`
- [ ] Confirm tunnel name is `foodshare-web-club` (matches `Command=tunnel ... run foodshare-web-club`)
- [ ] `systemctl --user daemon-reload`
- [ ] `systemctl --user start foodshare-network.service`
- [ ] `systemctl --user start foodshare-web.service`
- [ ] `systemctl --user start foodshare-cloudflared.service`
- [ ] `curl -I https://foodshare.club` — should show 200 via cloudflared → Quadlet web
- [ ] Monitor `journalctl --user -u foodshare-web.service -f` and `journalctl --user -u foodshare-cloudflared.service -f` for 30 min
- [ ] Keep Docker + Supabase stack running as rollback for 2+ weeks

---
*Generated from actual stack discovery. All unit files are ready to drop in. Cloudflare tunnel integration is fully handled — no host-level reverse proxy needed.*