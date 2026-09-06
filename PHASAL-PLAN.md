# FoodShare Phasal Plan - Incremental Modernization

## Overview
This plan systematically modernizes, componentizes, and modularizes the entire FoodShare codebase using bleeding-edge practices. Each phase builds incrementally on the previous one, with commits and CI/CD verification after each step.

## Current State Assessment
- **foodshare-web**: Next.js 16.3.3, React 19, Tailwind CSS 4, TypeScript 5.9.3, React Compiler enabled, Cache Components enabled
- **foodshare-app**: Skip mobile app with Clean Architecture (Domain/Presentation/ViewModels already structured)
- **foodshare-backend**: Deno/Supabase API, Cron, Functions
- **foodshare-tools**: Rust CLI tools

## Phase 1: Foundation & Tooling Setup ✅
**Goal**: Establish best-in-class tooling, linting, and type safety across all domains.

### Steps:
1. **Update Biome config to Tailwind CSS 4 best practices**
   - Enable `optimizeImports` for removing unused Tailwind classes
   - Configure `unknownAtRules` for `@theme` directives
   - Set up `composites` for custom class combinations

2. **Oxlint configuration enhancements**
   - Add `lint/recommended` ruleset
   - Configure `package.json` `oxlint.config` for project-specific rules
   - Add import sorting and no-unused-vars rules

3. **TypeScript strict mode validation**
   - Verify `tsconfig.json` has `strict: true` across all projects
   - Add `noImplicitAny`, `strictNullChecks`, `noUnusedLocals` everywhere

4. **Commit & push verification**
   - `git add .`
   - `git commit -m "chore: establish baseline tooling and type strictness"`
   - `git push`
   - Verify CI/CD passes

---

## Phase 2: Web Component Deep Componentization
**Goal**: Breakdown web components into truly reusable, modular atoms/molecules/organisms with proper TypeScript typing.

### Key Observations:
- UI library atoms: Avatar, Divider, FrequencyBadge, GlassButton, LoadingSkeleton, StatusIndicator
- Components span: admin, analytics, asideProducts, carousel, challenges, chat, comments, containerForChat, demo, dev, drawerContainers, emailPreferences, error, ErrorBoundary, foodlytics, footer, forum, gpu, guards, header, languageSelector, leaflet, listingPersonCard, localization, location, main, maintenance, map, media, minifiedUserInfo, modals, navigation, newsletter, notifications, oneProduct, personCard, post-activity, productCard, productsLocation, profile, reports, requiredStar, searchField, security, settings, settingsCard, share, shared, skeletons, theme, topTips, ui-library, ui, universalDrawer, volunteerCard, volunteers

### Steps:
1. **Atom Standardization** - Ensure all atoms follow consistent prop patterns:
   - `asChild` pattern for wrap components
   - Proper `forwardRef` where needed
   - Consistent `className` merging with `tailwind-merge`

2. **Molecule Creation** - Combine atoms into molecules:
   - Create `SearchField` as standalone molecule (currently exists but could be extracted)
   - Create `StatusBadge` molecule from `FrequencyBadge` + `StatusIndicator`
   - Create `ActionToast` molecule from hook + component

3. **Organism Extraction** - Extract complex compositions:
   - Extract `ProductCard` variants into separate organisms
   - Create `UserProfileCard` organism from `personCard`, `Avatar`, `MinifiedUserInfo`
   - Create `NavigationHeader` organism from `NavbarWrapper`, `SearchBar`, `NavbarActions`

4. **Type-Safe Component Props** - Add comprehensive PropTypes:
   - Generate types from Zod schemas where applicable
   - Ensure all components accept `className` and `...rest` props properly

5. **Component Export Barrel** - Update `src/components/index.ts` with proper categorization:
   - Group by domain responsibility
   - Add JSDoc comments for each group
   - Ensure tree-shakeable exports (no default exports where possible)

6. **Commit & push verification**
   - Commit each set of component changes
   - Run `bun test` and `bun run lint:fix`
   - Verify no regressions

---

## Phase 3: Web App Modularization & Feature Structure
**Goal**: Organize features into independent, testable modules with clear boundaries.

### Current Feature Structure:
`auth, borrow, business, challenge, chat, donation, feedback, forum, fridge, guides, help, map, messages, my-posts, navigation, organisation, palette, profile, reports, settings, thing, user-listings, vegan, volunteer, wanted, zerowaste`

### Steps:
1. **Feature Barrels** - Create `src/features/[feature]/index.ts` for each feature:
   - Export only the public API for each feature
   - Group components, hooks, and utilities by feature
   - Prevent cross-feature import leakage

2. **Server Component Boundaries** - Ensure proper RSC/SSR patterns:
   - Mark truly server components with `export const` and no `"use client"` 
   - Move client-only logic to explicit client components
   - Use `use` hook for data fetching where appropriate (Next 16)

3. **Middleware Optimization** - Audit `src/middleware.ts`:
   - Reduce matcher scope to essential routes only
   - Add locale-based routing protection
   - Protect admin routes with proper auth guards

4. **App Router Optimization** - Audit `app/` directory:
   - Ensure `loading.tsx` provides skeleton for all routes
   - Ensure `error.tsx` handles errors gracefully
   - Add `not-found.tsx` for 404 cases
   - Verify all routes have proper `delay`/`searchParams` handling

5. **Cache Life Refinement** - Review `next.config.ts` cacheLife values:
   - Align with actual data freshness requirements
   - Add missing cache entries for new features
   - Enable `actionCache` for mutations

6. **Commit & push verification**
   - After each feature module, run full test suite
   - Verify bundle size doesn't increase
   - Check Next.js doesn't report RSC errors

---

## Phase 4: Skip App Architecture Deepening
**Goal**: Enhance the existing Clean Architecture with more modular use cases and test coverage.

### Current Structure (already good):
- Features → Data/Domain/Mocks/Presentation
- Domain → Models/Repositories/Services/UseCases

### Steps:
1. **Use Case Interface Abstraction** - Add protocol-oriented use cases:
   - Define `UseCase` protocol in Domain
   - Implement in Data layer
   - Allow mocking for UI preview without network

2. **ViewModel Standardization** - Unify Presentation layer:
   - All views should receive ViewModel, not domain models directly
   - Create ViewModel builders/factories
   - Ensure all Presentation views are purely functional

3. **Test Data Mock Expansion** - Expand `Features/*/Mocks/`:

4. **Feature Module Independence** - Ensure each feature can be built/tested in isolation:
   - Remove circular dependencies between features
   - Add feature-specific unit tests
   - Create `skip test` parity checks for iOS/Android

5. **Commit & push verification**
   - Run `bun tools/builder.ts --test` for cross-platform test
   - Verify Maestro tests still pass
   - Check Swift/Kotlin compilation

---

## Phase 5: Backend Modularization & API Enhancement
**Goal**: Modularize the Supabase/Deno backend with proper package structure.

### Steps:
1. **API Route Organization** - `packages/api/`:
   - Group routes by domain (users, products, listings, etc.)
   - Add proper OpenAPI/TypeGen types
   - Ensure consistent error handling middleware

2. **Function Enhancement** - `packages/functions/`:
   - Add CRON job type safety
   - Edge function modularization
   - Add idempotency keys for webhook handlers

3. **Sync Type Generation** - Enhance `sync:types` script:
   - Add generation for enum types
   - Add Zod validation schema generation
   - Ensure types stay in sync across web/app/backend

4. **Commit & push verification**
   - Run `bun run sync:types`
   - Verify TypeScript compilation across all projects
   - Check Supabase migrations

---

## Phase 6: Tooling & CLI Enhancement
**Goal**: Improve the foodshare-tools Rust CLI for better developer experience.

### Steps:
1. **TUI Enhancement** - `foodshare-tools/bin/fs-tui`:
   - Add real-time preview of component changes
   - Add color-coded health indicators
   - Add modular navigation between code sections

2. **Auto-Feature Generation** - Enhance `cli.ts auto`:
   - Generate feature skeletons for both web and mobile
   - Add component scaffolding with proper patterns
   - Add import barrel updates automatically

3. **Commit & push verification**
   - Run `bun ../foodshare-tools/cli.ts auto --quick`
   - Verify no breaking changes

---

## Phase 7: Integration & End-to-End
**Goal**: Full integration testing and CI/CD pipeline optimization.

### Steps:
1. **E2E Test Expansion** - Playwright tests:
   - Add cross-browser tests (Chrome, Firefox, Safari)
   - Add performance budgets in CI
   - Add accessibility (a11y) tests for all major flows

2. **Maestro Flow Coverage** - Mobile UI tests:
   - Ensure all 13 maestro flows have regression tests
   - Add offline/online transition testing
   - Add locale/language testing across all flows

3. **CI/CD Pipeline Optimization**:
   - Cache Next.js build artifacts
   - Cache Deno function deployments
   - Add bundle size regression detection
   - Add type check as gate

4. **Final Verification**:
   - Full `bun test:ci` run
   - Full `bun run lint:fix` 
   - `bun run build` success
   - Deploy preview generation

## Execution Strategy
- Each phase is incremental - no phase block others completely
- Commit after each logical step with descriptive messages
- Always verify CI/CD passes before moving to next phase
- Use feature flags for experimental modularization patterns