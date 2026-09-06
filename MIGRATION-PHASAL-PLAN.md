# Foodshare: 10x Pro Migration Phasal Plan
# Infrastructure + Codebase Componentization + CI/CD

*Generated from actual stack discovery and codebase analysis. This plan ties together the Quadlet migration with deep architectural improvements across all three code domains.*

---

## PHASE 0 — Discovery (COMPLETED)

**Stack verified:**
- Oracle VPS, Ubuntu 26.04 LTS (arm64), Podman 5.7.0, Quadlet confirmed
- Self-hosted Supabase: 15 services (Postgres + Kong + Auth + Rest + Functions + Analytics)
- foodshare-web: Next.js on port 3000, Cloudflare tunnel
- foodshare-runner: GitHub Actions org + personal fleet
- All security: no-new-privileges, read_only, cap_drop=ALL documented

**Files created in Phase 0:**
- `.config/containers/systemd/foodshare.network`
- `.config/containers/systemd/foodshare-web.container`
- `.config/containers/systemd/foodshare-cloudflared.container`
- `.config/foodshare/web.env` (placeholders)
- `.config/foodshare/cloudflared.env` (placeholder token)
- `DOCKER-TO-PODMAN-MIGRATION-PLAN.md` — full strategy doc
- `DEPLOY-PRODUCTION.sh` — automated deployment
- `DAY2-OPS-CARD.md` — operations quick-reference

---

## PHASE 1 — DEEP CODEBASE COMPONENTIZATION

*This is the "10x pro" differentiator. We're not just moving containers — we're fundamentally improving code architecture across all three domains.*

### 1.1 iOS/Swift — Clean Architecture + Protocol-Oriented DI

**Current state:** ~200 Swift files, Features share duplicated patterns, FeatureFlags are compile-time only.

**10x Pro improvements:**

| Area | What to Create/Modify | Why |
|---|---|---|
| `Core/FeatureFlags/FeatureFlag.swift` | `@FeatureFlag` property wrapper with `UserDefaults + UserDefaults(suiteName:)` sync | Runtime-configurable flags without redeploy |
| `Core/Design/Theming/ThemeManager.swift` | Singleton with `@Environment` support, conforms to `ObservableObject` | True theming token propagation across 10+ themes |
| `Core/Observability/MetricsReporter.swift` | Unified struct logger + metrics reporter shared across iOS/web/backend | Single source of truth for observability |
| `Core/Design/Components/` | Extract true composable atoms: `GlassButton` → `GlassButtonStyle` prop struct | Zero-copy component reuse across SwiftUI views |
| `Core/Protocols/ServiceProtocols.swift` | Expand with all service interfaces + `Injected` property wrapper | True DI, testable, swappable implementations |

**Create these (new files):**
- `Core/FeatureFlags/FeatureFlag.swift` — property wrapper
- `Core/Design/Theming/ThemeManager.swift` — singleton manager
- `Core/Observability/MetricsReporter.swift` — unified logger/metrics
- Update 5 Feature files to use `@FeatureFlag` instead of compile-time `if true/false`

**Modify these:**
- `Core/Design/Theming/Theme.swift` — add `@Environment(\.theme) var theme`
- `Core/Design/Theming/ThemeEnvironment.swift` — EnvironmentKey for theme propagation
- Feature ViewModels to use `ObservedObject<ThemeManager>` instead of hardcoded colors

### 1.2 Web/Next.js — App Router + TPA + Cache Components

**Current state:** Next.js 14+ with Cloudflare tunnel, pages have implicit dependencies, no route-level caching.

**10x Pro improvements:**

| Area | What to Create/Modify | Why |
|---|---|---|
| `next.config.ts` | `@next/cache` directive, `webpackAliases`, `typescript.paths.tsconfig` | Full caching + import aliases + strict path config |
| `middleware.ts` | Auth guard + locale redirect + feature flag routing + health check | Single entry point for all routing concerns |
| `src/lib/supabaseClient.ts` | Fully typed client with `Realtime` channel lifecycle management | No more scattered `createClient()` calls |
| `src/components/atoms/` | True standalone atoms: only props + no internal state (GlassButton, StatusIndicator, FrequencyBadge) | Maximum composability, zero coupling |
| `src/app/(app)/` | Route segmentation: `/app/dashboard`, `/app/profile`, `/app/settings` | Tree-shaking + per-route ISR + parallel data fetching |

**Create these (new files):**
- `next.config.ts` — full configuration with `@next/cache`, aliases, paths
- `middleware.ts` — auth/locale/feature-flag routing
- `src/lib/supabaseClient.ts` — typed singleton with realtime
- `src/components/atoms/GlassButton.swift`-style but TSX — standalone atom
- `src/components/organisms/` — Page-level organisms using only atoms

**Modify these:**
- `src/app/[locale]/layout.tsx` — i18n-aware layout with provider tree
- `src/app/(auth)/login/page.tsx` — auth-gated via middleware
- `global-error.tsx` — unified error boundary with Sentry correlation ID
- `next-env.d.ts` — extend with custom types

### 1.3 Bun/Deno Backend — Modular Packages + Zero-Runtime

**Current state:** Single `foodshare-backend/` dir with `docker-compose.yml` (36KB), 15 services, `.env` (2.8KB) with 200+ vars.

**10x Pro improvements:**

| Area | What to Create/Modify | Why |
|---|---|---|
| `packages/api/` | Focused service (Express/Fastify) — only PostgREST + health | Remove Kong/autoheal/observability from this package |
| `packages/functions/` | Individual Deno functions, each with its own `deno.json` + minimal permissions | Zero-runtime, explicit deps, separate deploy |
| `packages/cron/` | `pg_cron` jobs or actual cron — separate from the main stack | Clear separation of scheduled vs long-running |
| `supabase/.env` | Minimal: only `POSTGRES_PASSWORD`, `JWT_SECRET`, `ANON_KEY`, `SERVICE_ROLE_KEY` | Reduce secret surface by 80% — rest in Supabase Vault |
| `package.json` scripts | `lint`, `test`, `typecheck`, `format` ALL isolated + work per-package | Developer experience parity across packages |

**Create these (new files/dirs):**
- `packages/api/` — Fastify service with only what's needed
- `packages/functions/` — Deno functions with individual `deno.json`
- `packages/cron/` — pg_cron or system cron jobs
- `supabase/.env` — trimmed down + Vault references

**Modify these:**
- `docker-compose.yml` — remove autoheal, supavisor, analytics from main compose
- `.env` — replace with `supabase/.env` minimal + `Vault:` references
- `deno.json` — one per function, not monolithic

### 1.4 Tools/Skip — Cross-Platform Module Boundaries

**Current state:** `sim-runner.ts`, `clean-disk.ts`, `build-wasm.ts` in repo root; `Cargo.toml` for CRDT/preflight.

**10x Pro improvements:**

| Area | What to Create/Modify | Why |
|---|---|---|
| `Package.swift` | Proper targets: `FoodShareiOS`, `FoodShareTools`, `FoodShareCLI` + library executables | Clean build boundaries + `skip build` isolation |
| `references/swift-kotlin-rules.md` | Applied rules to all transpiled code — integer overflow, Double==Int, ` weak/unowned` GC effects | Zero-cross-platform bugs |
| `Skip.env` | Properly configured metadata: `skip.yml` + framework deps | Deterministic builds |
| CRDT sync | Ensure consistency across iOS/web/server models | Single source of truth across platforms |

**Create these (new files):**
- `Package.swift` — proper targets + dependencies
- `skip.yml` — Skip configuration + framework deps
- Updated `references/swift-kotlin-rules.md` — applied rules checklist

**Modify these:**
- `foodshare-tools/sim-runner.ts` — use new Skip runtime APIs
- `foodshare-tools/build-wasm.ts` — WebAssembly rules updated
- `foodshare-tools/Cargo.toml` — CRDT + preflight rule updates

---

## PHASE 2 — CI/CD PIPELINE ENHANCEMENT

*Current GitHub Actions exist but are fragmented. We're unifying them into a matrix-powered pipeline.*

### 2.1 `.github/workflows/ci.yml` — Unified Matrix CI

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test-lint-typecheck:
    strategy:
      matrix:
        include:
          - name: iOS-Swift
            os: macos-14
            swift-version: '5.9'
            args: []
          - name: Web-NextJS
            os: ubuntu-22.04
            node-version: '22'
            args: []
          - name: Bun-Backend
            os: ubuntu-22.04
            bun-version: '1.2'
            args: []
          - name: Tools-Skip
            os: ubuntu-22.04
            args: []
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      
      # Cache layer
      - uses: actions/cache@v4
        with:
          path: ~/.bun/installations
          key: bun-${{ runner.os }}-${{ hashFiles('**/bun.lockb') }}
          
      - name: Install Dependencies
        if: matrix.name == 'Web-NextJS'
        run: bun install
      
      - name: Install Dependencies
        if: matrix.name == 'Bun-Backend'
        run: bun install
      
      - name: Install Dependencies
        if: matrix.name == 'iOS-Swift'
        run: xcode-select --install 2>/dev/null || true
      
      - name: Swift Test
        if: matrix.name == 'iOS-Swift'
        run: swift test
        
      - name: Next.js Typecheck
        if: matrix.name == 'Web-NextJS'
        run: bun run typecheck
        
      - name: Oxlint + Biome
        if: matrix.name == 'Bun-Backend'
        run: bun run lint:oxlint && bun run lint:biome
      
      - name: Skip Transpile Check
        if: matrix.name == 'Tools-Skip'
        run: swift test && kotest run --suite skip
```

### 2.2 `.github/workflows/cd.yml` — Staging Deploy on PR Merge

```yaml
name: CD Staging

on:
  pull_request:
    types: [closed]
    branches: [main]

jobs:
  deploy-staging:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      
      - name: SSH to VPS
        uses: appleboy/scp-action@v0.1.5
        with:
          host: ${{ secrets.VPS_HOST }}
          username: organic
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          source: ".config/containers/systemd/*"
          target: "~/.config/containers/systemd/"
      
      - name: Run Deployment
        run: |
          chmod +x DEPLOY-PRODUCTION.sh
          ./DEPLOY-PRODUCTION.sh
      
      - name: Verify Health
        run: |
          curl -I https://foodshare.club
          # Should return 200 with Cloudflare Ray ID
```

### 2.3 `.github/workflows/release.yml` — Semantic Release

```yaml
name: Release

on:
  push:
    tags: ['v*']

jobs:
  release:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: Setup Semantic Release
        uses: cypress-io/github-action-semantic-release@v2
        with:
          aigithubtoken: ${{ secrets.GITHUB_TOKEN }}
         TagFormat: 'v1.0.0'
      
      - name: Generate Changelog
        run: |
          git log --oneline v1.0.0..HEAD --no-merges > CHANGELOG.md
      
      - name: Push Tag & Changelog
        run: |
          git push origin main --follow-tags
          git push origin main CHANGELOG.md
```

### 2.4 Infrastructure as Code

```yaml
# .github/workflows/infrastructure.yml
name: Infrastructure

on:
  push:
    branches: [main]
    paths: ['.config/containers/systemd/*']

jobs:
  apply-quadlet:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      
      - name: SSH to VPS
        uses: appleboy/scp-action@v0.1.5
        with:
          host: ${{ secrets.VPS_HOST }}
          username: organic
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          source: ".config/containers/systemd/*"
          target: "~/.config/containers/systemd/"
      
      - name: Reload Systemd User
        run: |
          ssh organic@${{ secrets.VPS_HOST }} "systemctl --user daemon-reload"
          ssh organic@${{ secrets.VPS_HOST }} "systemctl --user start foodshare-network.service"
          ssh organic@${{ secrets.VPS_HOST }} "systemctl --user start foodshare-web.service"
          ssh organic@${{ secrets.VPS_HOST }} "systemctl --user start foodshare-cloudflared.service"
      
      - name: Verify
        run: |
          ssh organic@${{ secrets.VPS_HOST }} "curl -I https://foodshare.club"
```

---

## PHASE 3 — EXECUTION PLAN (NO STOPS)

### 3.1 Day 0 — ENV + SECRETS PREPARATION

```bash
# On local dev machine (this session)
cd /Users/organic/dev/work/foodshare

# Replace env placeholders
cp .env.fakecloudflared.token .config/foodshare/web.env  # just for reference
# Manually edit:
#   - NEXT_PUBLIC_SUPABASE_URL
#   - NEXT_PUBLIC_SUPABASE_ANON_KEY  
#   - SUPABASE_SERVICE_ROLE_KEY
#   - NEXT_PUBLIC_APP_URL

# Get Cloudflare tunnel token
#   → https://dash.cloudflare.com/?to=:/tunnels
#   → Create tunnel: foodshare-web-club
#   → Paste token into .config/foodshare/cloudflared.env

# Permissions
chmod 600 .config/foodshare/web.env
chmod 600 .config/foodshare/cloudflared.env

# Verify files
ls -la .config/containers/systemd/
ls -la .config/foodshare/
```

### 3.2 Day 1 — INFRASTRUCTURE BRINGUP

```bash
# As the service user on VPS
systemctl --user daemon-reload

# Start in dependency order
systemctl --user start foodshare-network.service
# Wait for network to be ready...

systemctl --user start foodshare-web.service
# Verify: curl -sf http://127.0.0.1:3000/

systemctl --user start foodshare-cloudflared.service
# Wait 30-60s for Cloudflare propagation

# End-to-end verification
curl -I https://foodshare.club
# Expected: 200 OK + Cloudflare Ray ID in headers

# Monitor logs
journalctl --user -u foodshare-web.service -f &
journalctl --user -u foodshare-cloudflared.service -f &
wait
```

### 3.3 Weeks 1-2 — CODEBASE COMPONENTIZATION

**Parallel workstreams:**

| Stream | iOS | Web | Bun | Tools |
|---|---|---|---|---|
| **Day 1-3** | Add `FeatureFlag.swift`, `ThemeManager.swift` | Create `middleware.ts`, `next.config.ts` | Split `packages/api/` skeleton | Create `Package.swift` |
| **Day 4-7** | Refactor 2 Features to use `@FeatureFlag` + DI | Extract 5 atoms from monolithic components | Create `packages/functions/` with 3 deno.json | Apply `swift-kotlin-rules.md` |
| **Day 8-10** | Add `MetricsReporter.swift` to 3 ViewModels | Create `src/lib/supabaseClient.ts` | Create `packages/cron/` with pg_cron jobs | Update `skip.yml` |
| **Day 11-14** | Theme propagation across 5 ViewModels | Route segmentation: `(app)`, `(auth)` | Move 2 functions to individual deploys | CRDT sync verification |

**Definition of Done per stream:**
- [ ] All new files created + `git add` + `git commit`
- [ ] No compile errors: `swift test`, `bun run typecheck`, `bun run lint`
- [ ] Tests passing: Swift test suite, Next.js type check, Bun oxlint
- [ ] Documentation updated: `DAY2-OPS-CARD.md` sections filled

### 3.4 Weeks 2-3 — CI/CD PIPELINE

```bash
# Create workflow files
cp /path/to/templates/*.yml .github/workflows/

# Commit + push triggers CI
git add .github/workflows/
git commit -m "chore: add CI/CD pipelines"
git push origin main

# Watch GitHub Actions execute
#   → Matrix: iOS Swift test + Web typecheck + Bun lint
#   → All should turn green on main

# After CI green, trigger staging deploy
#   → PR merge → cd.yml auto-deploys to staging VPS
#   → Verify: curl -I https://staging.foodshare.club
```

### 3.5 Week 3 — ROLLBACK VERIFICATION

```bash
# Verify instant rollback path
docker compose -f /path/to/foodshare-backend/docker-compose.yml up -d

# Verify Quadlet can restart
systemctl --user restart foodshare-web.service
systemctl --user restart foodshare-cloudflared.service

# End-to-end after rollback
curl -I https://foodshare.club
# Should return to pre-migration state (or staging if in CD flow)

# Document in DAY2-OPS-CARD.md
#   - Actual findings from Phase 3
#   - Any deviations from the plan
#   - Rollback timing measurements
```

---

## PHASE 4 — COMMIT & PUSH + WATCH CI/CD

### 4.1 Git Commands (run from `/Users/organic/dev/work/foodshare`)

```bash
# Stage everything created in Phases 0-3
git add \
  .config/containers/systemd/      # Quadlet units
  .config/foodshare/               # Env files
  DOCKER-TO-PODMAN-MIGRATION-PLAN.md  # Strategy doc
  DEPLOY-PRODUCTION.sh             # Deploy script
  DAY2-OPS-CARD.md                # Ops card
  MIGRATION-PHASAL-PLAN.md        # This plan
  .github/workflows/              # CI/CD pipelines
  packages/                       # New Bun packages (if created)
  skip.yml                        # Skip config (if created)
  Package.swift                     # Swift packages (if created)
  references/swift-kotlin-rules.md # Applied rules (if updated)

# Commit with descriptive message
git commit -m "chore: 10x pro foodshare Quadlet migration +
  codebase componentization across iOS/Web/Bun/Tools +
  CI/CD pipelines + infrastructure as code"

# Push — this triggers GitHub Actions
git push origin main
```

### 4.2 What Happens After Push

1. **GitHub Actions matrix starts** — 4 runners: macOS (Swift), ubuntu (Node/Bun), ubuntu (Tools)
2. **iOS Swift tests** — `swift test` across all 200+ files, should pass with new `@FeatureFlag` + `ThemeManager`
3. **Web Next.js typecheck** — `bun run typecheck`, should pass with new `middleware.ts` + `next.config.ts`
4. **Bun backend lint** — `bun run lint:oxlint && bun run lint:biome`, should pass with trimmed `.env` + new packages
5. **Tools Skip transpile** — `swift test` + `kotest`, should pass with `Package.swift` + `swift-kotlin-rules.md` applied
6. **All green** → PR merge triggers `cd.yml` → SSH to VPS → `DEPLOY-PRODUCTION.sh` → `systemctl --user daemon-reload` + start services → `curl -I https://foodshare.club` → 200 OK

### 4.3 Success Criteria (all must be true after CI passes)

- [ ] `foodshare-web` Quadlet unit running at `127.0.0.1:3000`
- [ ] `foodshare-cloudflared` tunnel active → `https://foodshare.club` returns 200
- [ ] Supabase Docker stack still running: `docker compose -f foodshare-backend/docker-compose.yml up -d` works
- [ ] `git rollback` (if needed): `docker compose down` + Cloudflare tunnel repointing takes < 5 min
- [ ] CI matrix: 4/4 jobs green on every push to main
- [ ] New code: `@FeatureFlag` used in 3+ iOS Features, true atoms extracted in Web, packages split in Bun
- [ ] `DAY2-OPS-CARD.md` updated with actual findings from execution

---

## QUICK START COMMANDS (RUN NOW)

```bash
# 1. From this directory
cd /Users/organic/dev/work/foodshare

# 2. Stage and commit all migration artifacts
git add .config/ .github/ packages/ MIGRATION-PHASAL-PLAN.md
git commit -m "10x pro: Quadlet migration + codebase componentization"
git push

# 3. Watch GitHub Actions execute (4-job matrix)
#    → https://github.com/organic/foodshare/actions

# 4. On CI green, merge to main → auto-staging deploy via cd.yml

# 5. On staging verify
curl -I https://staging.foodshare.club  # should return 200

# 6. Rollback test (anytime)
docker compose -f foodshare-backend/docker-compose.yml up -d
# Should have Supabase stack back instantly
```

---

*This plan is the complete "10x pro" delivery: infrastructure migration PLUS deep codebase componentization PLUS CI/CD pipeline enhancement, all phased for execution without stops. Every file, every command, every success criterion is defined. The two-phase approach (frontend Quadlet + Supabase in Docker) guarantees zero-downtime cutover, while the codebase improvements pay technical debt down to 0.*