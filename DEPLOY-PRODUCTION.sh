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

# Resolve the service user's home robustly (works under sudo and direct login).
SERVICE_USER="${SUDO_USER:-${USER:-$(whoami)}}"
USER_HOME="$(eval echo "~${SERVICE_USER}")"
QUADLET_DIR="$USER_HOME/.config/containers/systemd"
FOODSHARE_ENV="$USER_HOME/.config/foodshare"
# Directory containing this script — the repo checkout (units live in .config/containers/systemd).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  echo "systemctl not found. This script requires systemd --user."
  exit 1
fi

# systemd --user needs a runtime dir; linger keeps it alive without login.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
loginctl enable-linger "$SERVICE_USER" 2>/dev/null || true
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
  echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR missing. Ensure linger is enabled and re-login."
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
# 2. Sync Quadlet unit files from the repo (single source of truth)
# -------------------------------------------------------
echo ""
echo ">>> Syncing Quadlet unit files..."

REPO_UNITS="$SCRIPT_DIR/.config/containers/systemd"
if [ -d "$REPO_UNITS" ]; then
  cp -f "$REPO_UNITS/foodshare.network" "$QUADLET_DIR/foodshare.network"
  cp -f "$REPO_UNITS/foodshare-web.container" "$QUADLET_DIR/foodshare-web.container"
  cp -f "$REPO_UNITS/foodshare-cloudflared.container" "$QUADLET_DIR/foodshare-cloudflared.container"
  echo "  • synced from $REPO_UNITS (repo is source of truth)"
else
  echo "  • repo units not found at $REPO_UNITS — run from a full checkout"
  exit 1
fi

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

# Observability (Sentry) — required for issue/PR correlation
# NEXT_PUBLIC_SENTRY_DSN=https://o479112.ingest.sentry.io/560687
# SENTRY_DSN=https://o479112.ingest.sentry.io/560687
# SENTRY_ENVIRONMENT=production
# SENTRY_RELEASE=3.0.2
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

# daemon-reload (as the user) — must succeed, otherwise units are stale.
systemctl --user daemon-reload

# Start network first (prerequisite) — fail fast, no masking.
echo "  → Starting foodshare-network.service..."
systemctl --user start foodshare-network.service
sleep 2
systemctl --user is-active --quiet foodshare-network.service

# Start web container
echo "  → Starting foodshare-web.service..."
systemctl --user restart foodshare-web.service
sleep 3
systemctl --user is-active --quiet foodshare-web.service

# Start cloudflared tunnel
echo "  → Starting foodshare-cloudflared.service..."
systemctl --user restart foodshare-cloudflared.service
sleep 3
systemctl --user is-active --quiet foodshare-cloudflared.service

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

# Cloudflare tunnel liveness via systemd (metrics port removed from unit)
echo ""
echo "  → Checking cloudflared service state..."
if systemctl --user is-active --quiet foodshare-cloudflared.service 2>/dev/null; then
  echo "  ✓ foodshare-cloudflared.service active"
else
  echo "  ⚠ foodshare-cloudflared.service not active (tunnel may still be provisioning)"
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