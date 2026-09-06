# Workspace Rules

- **Core Toolchain Mandate (Bun, Turbopack, Oxlint, Biome, Hono):**
  - **Bun:** For all package management and script execution tasks across `foodshare-web`, `foodshare-backend`, and `foodshare-app`, ALWAYS use `bun` (nightly Rust base version) instead of `npm`, `npx`, `yarn`, or `pnpm`.
  - **Turbopack:** For `foodshare-web`, always use Next.js Turbopack compiler (`bun next dev --turbopack` & `bun next build --turbopack`).
  - **Oxlint:** Enforce Rust-based fast linting (`oxlint` / `bunx oxlint`) across JS/TS/JSON code in all components.
  - **Biome:** Enforce Rust-based fast formatting & linting (`biome` / `bunx biome check`) across all projects.
  - **Hono:** Use Hono web/edge framework for ultra-fast REST API routing in both Next.js App Router and Supabase Deno Edge Functions.

- **Web Frontend (`foodshare-web`) Stack:**
  - **Framework:** Next.js 16 (App Router exclusively) with Hono API routes (`src/app/api/[[...route]]/route.ts`).
  - **React Features:** Enforce React 19 best practices (`useActionState`, `useFormStatus`, `useOptimistic`, and `use()` hook patterns). Do not use deprecated React 18 patterns for forms.
  - **Styling:** Tailwind CSS v4 with the specialized "Liquid Glass" aesthetic. Prioritize micro-animations and View Transitions.
  - **Caching:** Leverage Turbopack caching paradigms correctly to prevent directive crashes.
  - **i18n:** Utilize `next-intl` for the 21 supported languages. Always sync translation keys using `bun run translations:sync`.
  - **Deployment:** The frontend is self-hosted via Docker Compose on a VPS and exposed exclusively via Cloudflare Zero Trust Tunnels (`foodshare-frontend`). DO NOT use Vercel for deployment or DNS records.
  - **Secrets Management & Deployment:** GitHub Repository Secrets MUST be used for CI/CD deployments across the domain. All build arguments and environment variables (e.g., `SITE_DOMAIN`, OAuth keys, `CLOUDFLARE_TUNNEL_TOKEN`, `VPS_HOST`) are injected through the `.github/workflows/web.yml` CI/CD pipeline. Avoid hardcoding domain names or IP addresses; use a single domain variable like `SITE_DOMAIN` to derive URLs dynamically (e.g., `NEXT_PUBLIC_APP_URL: https://${{ secrets.SITE_DOMAIN }}`). While CI/CD is the primary deployment method, manual SSH access and `.env` modifications on the VPS are permitted when explicitly requested by the user for debugging or administrative purposes.

- **Backend (`foodshare-backend`) Stack:**
  - **Infrastructure:** Supabase ecosystem.
  - **Edge Functions:** Written in Deno (TypeScript) integrated with Hono API router (`npm:hono`). Use `Deno.serve`, `createAPIHandler`, and Hono sub-routers.
  - **Testing:** Scaffold robust Deno unit tests for Edge Functions.
  - **Database Migration:** Generate SQL migrations in `supabase/migrations`. ALWAYS sync TypeScript types to the frontend via `bunx supabase gen types typescript` after applying schema changes.
  - **AI / Vector:** Utilize Supabase Vector (pgvector) and Edge AI workflows for embeddings and similarity search.
  - **Secrets:** Safely integrate highly sensitive data using Supabase Vault in Postgres, and manage environment variables for Deno Edge Functions using Supabase Edge Function Secrets (via Supabase CLI/Dashboard). Do not hardcode API keys.

- **Mobile Application (`foodshare-app`) Stack:**
  - **Framework:** Skip (for cross-platform SwiftUI to Kotlin transpilation) and native SwiftUI (iOS 27 patterns).
  - **Tooling:** Bun, Oxlint, Biome, and Hono integration for localizations, helper scripts, and API contracts.
  - **Testing:** Maestro (`.maestro/`) for automated declarative E2E UI testing and simulator/emulator matrix execution (`bun run maestro:test`, `bun run maestro:matrix`).
  - **Design System:** Use Liquid Glass tokens and ensure cross-platform safety for Skip Fuse patterns.
  - **Xcode Cloud & Versioning Pipeline:** Enforce target-level build number stamping (`Enforce Build Number` phase) with base offset (> 367) so exported IPAs pass TestFlight ingestion without version conflict.
  - **Skip Transpilation & Bridging Rules:** NEVER declare local structs or enums inside functions (causes Skip Kotlin transpilation failure). Always define DTOs and Decodable models at file or class scope. Avoid untyped dictionary parsing to prevent Kotlin runtime type erasure crashes. On bridged `View` structs, all `@State`, `@Environment`, `@Binding`, `@FocusState`, and subview structs MUST be `internal` (omit `private`) so Skip's companion bridge files can generate without access level compilation errors.
  - **Swift Concurrency & SDK Best Practices:** Enforce a 0-compiler-warning baseline. Apply `@MainActor` on SwiftUI views/viewmodels, `isolated deinit` for isolated state cleanup, and `@Sendable` on escaping closures. Use direct `client.from(...)` and `client.rpc(...)` (avoid deprecated `client.database`).

