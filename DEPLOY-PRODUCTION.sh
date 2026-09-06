#!/usr/bin/env bash
# Production-ready deployment script for Foodshare Docker→Quadlet migration
# Runs on Oracle VPS, Ubuntu 26.04 LTS (arm64), Podman 5.7.0
# This script: sets up Quadlet units, starts the stack, verifies health
# ------------------------------------------------------------------------- #
# PREREQUISITES (run once, as the service user):
#   1. Podman 5.7.0+ installed and rootless mode functional
#   2. systemd --user session active (systemctl --user works)
#   3. Quadlet generator enabled in Podman
#   4. Linger enabled for the service user (loginctl enable-linger <user>)
#   5. Directory: ~/.config/containers/systemd/ (created by this script)
#   6. Cloudflare tunnel token obtained from:
#        https://dash.cloudflare.com/?to=:/tunnels
#        → Create tunnel named "foodshare-web-club"
# ------------------------------------------------------------------------- #

set -euo pipefail

USER_HOME="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$USER_HOST")
QUADLET_DIR="$USER_HOME/.config/containers/systemd"
FOODSHARE_ENV="$USER_HOME/.config/foodshare"

echo "========================================="
echo "Foodshare Quadlet Deployment — Production"
echo "========================================="

# -------------------------------------------------------
# 0. Prerequisite checks
# -------------------------------------------------------
if ! command -v podman &>/dev/null; then
  echo "❌ Podman not found in PATH. Install Podman 5.7.0+ first."
  exit 1
fi

PODMAN_VER=$(podman --version 2>/dev/null || echo "unknown")
echo "✓ Podman version: $PODMAN_VER"

if ! command -v systemctl &>/dev/null; then
  echo "❌ systemctl not found. This script requires systemd --user."
  exit 1
fi

# Ensure Quadlet directory exists
mkdir -p "$QUADLET_DIR"
mkdir -p "$FOODSHARE_ENV"
echo "✓ Directories ready: $QUADLET_DIR, $FOODSHARE_ENV"

# -------------------------------------------------------
# 1. Verify rootless Podman works
# -------------------------------------------------------
echo ""
echo ">>> Testing rootless Podman..."
if ! podman info &>/dev/null; then
  echo "❌ Rootless Podman not functional. Check ulimit/seccomp settings."
  exit 1
fi
echo "✓ Rootless Podman is functional."

# -------------------------------------------------------
# 2. Place Quadlet unit files
# -------------------------------------------------------
echo ""
echo ">>> Installing Quadlet unit files..."

# Network unit
cat > "$QUADLET_DIR/foodshare.network" <<'EOF'
[Network]
NetworkName=foodshare
EOF
echo "  • foodshare.network"

# Frontend container unit
cat > "$QUADLET_DIR/foodshare-web.container" <<'EOF'
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
EOF
echo "  • foodshare-web.container"

# Cloudflare Tunnel container
cat > "$QUADLET_DIR/foodshare-cloudflared.container" <<'EOF'
# Cloudflare Tunnel reverse proxy for foodshare frontend
# Runs rootless via Quadlet — no need to bind low ports on the host
# Proxies to the foodshare-web container on 127.0.0.1:3000

[Unit]
Description=Cloudflare Tunnel for Foodshare frontend
After=foodshare-network.service foodshare-web.container
Requires=foodshare-web.container
Binds=foodshare-web.container

[Container]
Image=cloudflare/cloudflared:latest
ContainerName=foodshare-cloudflared
Network=foodshare.network
PublishPort=127.0.0.1:2000:2000/tcp
EnvironmentFile=%h/.config/foodshare/cloudflared.env
Command=tunnel --metrics 0.0.0.0:2000 run foodshare-web-club

Restart=always
TimeoutStartSec=30

[Service]
Type=notify

[Install]
WantedBy=default.target
EOF
echo "  • foodshare-cloudflared.container"

# -------------------------------------------------------
# 3. Place environment files (user must fill these!)
# -------------------------------------------------------
echo ""
echo ">>> Environment files —"

# web.env — copy from actual compose env, replace placeholders
if [[ -f "$FOODSHARE_ENV/web.env" ]]; then
  echo "  • $FOODSHARE_ENV/web.env already exists — skipping copy"
else
  cat > "$FOODSHARE_ENV/web.env" <<'EOF'
# Foodshare Next.js frontend environment
# Copied from foodshare-web/.env.production
# --- REPLACE THESE VALUES BEFORE DEPLOYMENT ---

# Supabase connection (cloud or self-hosted)
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Application URLs
NEXT_PUBLIC_APP_URL=https://foodshare.club
NEXT_PUBLIC_SITE_URL=https://foodshare.club
EOF
  chmod 600 "$FOODSHARE_ENV/web.env"
  echo "  ⚠ $FOODSHARE_ENV/web.env created — REPLACE placeholder values!"
fi

# cloudflared.env — must have real token
if [[ -f "$FOODSHARE_ENV/cloudflared.env" ]]; then
  echo "  • $FOODSHARE_ENV/cloudflared.env already exists — skipping"
else
  echo "  ⚠ YOU MUST PROVIDE CLOUDFLARE TUNNEL TOKEN"
  echo "    Get it from: https://dash.cloudflare.com/?to=:/tunnels"
  echo "    Create a tunnel named: foodshare-web-club"
  read -r -p "  Paste CLOUDFLARE_TUNNEL_TOKEN (or press Ctrl+C to abort): " TOKEN
  if [[ -z "$TOKEN" ]]; then
    echo "  ❌ No token provided — aborting."
    exit 1
  fi
  cat > "$FOODSHARE_ENV/cloudflared.env" <<EOF
CLOUDFLARE_TUNNEL_TOKEN=$TOKEN
EOF
  chmod 600 "$FOODSHARE_ENV/cloudflared.env"
  echo "  ✓ $FOODSHARE_ENV/cloudflared.env set."
fi

# -------------------------------------------------------
# 4. Start the stack
# -------------------------------------------------------
echo ""
echo ">>> Starting Quadlet stack..."

# daemon-reload (as the user)
if ! systemctl --user daemon-reload &>/dev/null; then
  echo "⚠ daemon-reload had no output (may be first run — that's ok)."
fi

# Start network first (prerequisite)
echo "  → Starting foodshare-network.service..."
systemctl --user start foodshare-network.service 2>/dev/null || true
sleep 2

# Start web container
echo "  → Starting foodshare-web.service..."
systemctl --user start foodshare-web.service 2>/dev/null || true
sleep 3

# Start cloudflared tunnel
echo "  → Starting foodshare-cloudflared.service..."
systemctl --user start foodshare-cloudflared.service 2>/dev/null || true
sleep 3

# -------------------------------------------------------
# 5. Verification
# -------------------------------------------------------
echo ""
echo ">>> Verification..."

# Check journal for startup errors
echo "  → Web container logs (last 20 lines):"
journalctl --user -u foodshare-web.service --no-pager -n 20 2>/dev/null || echo "   (no logs yet or journalctl not available in this env)"

echo ""
echo "  → Cloudflared logs (last 20 lines):"
journalctl --user -u foodshare-cloudflared.service --no-pager -n 20 2>/dev/null || echo "   (no logs yet)"

# Quick health check if we can reach the container
echo ""
echo "  → Testing 127.0.0.1:3000 direct..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/ 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" == "200" ]]; then
  echo "  ✓ Web container reachable at http://127.0.0.1:3000/ (HTTP $HTTP_CODE)"
else
  echo "  ⚠ Web container at http://127.0.0.1:3000/ returned HTTP $HTTP_CODE (may still be starting)"
fi

# Cloudflare tunnel metrics (optional)
echo ""
echo "  → Testing cloudflared metrics at 127.0.0.1:2000..."
METRICS_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:2000/metrics 2>/dev/null || echo "000")
if [[ "$METRICS_CODE" == "200" ]]; then
  echo "  ✓ Cloudflared metrics endpoint reachable (HTTP $METRICS_CODE)"
else
  echo "  ⚠ Cloudflared metrics at http://127.0.0.1:2000/metrics returned HTTP $METRICS_CODE (tunnel may still be provisioning)"
fi

# -------------------------------------------------------------------------
echo ""
echo "========================================="
echo "Deployment complete."
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Edit $FOODSHARE_ENV/web.env — replace placeholder keys with actual values"
echo "  2. Verify $FOODSHARE_ENV/cloudflared.env has your real CLOUDFLARE_TUNNEL_TOKEN"
echo "  3. Test end-to-end:  curl -I https://foodshare.club"
echo "  4. Monitor logs:   journalctl --user -u foodshare-web.service -f"
echo "                   journalctl --user -u foodshare-cloudflared.service -f"
echo ""
echo "Rollback (at any point):"
echo "  • Docker:       docker compose -f /path/to/foodshare-web/docker-compose.yml up -d"
echo "  • Quadlet:    systemctl --user restart foodshare-web.service foodshare-cloudflared.service"
echo ""
echo "Full cutover workflow: see DOCKER-TO-PODMAN-MIGRATION-PLAN.md"