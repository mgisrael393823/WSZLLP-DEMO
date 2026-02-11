# Repository UX & Architecture Review

## Summary

This repository has strong domain coverage and useful automation, but maintainability is being constrained by **surface-area sprawl**, **state management centralization**, and **inconsistent quality gates**. The product UX is functional, but there are several opportunities to improve accessibility, error handling clarity, and developer onboarding.

### What is working well
- Clear repo-level warning/intent in root `README.md` for demo vs production separation.
- Good breadth of scripts and tests already present.
- Existing effort toward component and accessibility audits (`audit:components`, `audit:a11y`).

### Primary risks
1. Over-centralized state/reducer architecture in `DataContext` makes feature changes expensive and fragile.
2. Route composition and UI orchestration in `App.tsx` are large and difficult to reason about.
3. Test suite trust is reduced due to failing unit tests and potential drift between implementation and assertions.
4. Duplicate infrastructure modules (e.g., two Supabase client initializers) create long-term configuration drift risk.
5. Documentation is abundant but fragmented, making onboarding costly.

---

## Key findings & issues

## 1) Monolithic state management in `DataContext`

**Problem**  
`src/context/DataContext.tsx` defines a very large app state and reducer handling many bounded contexts (cases, hearings, documents, invoices, workflows, notifications, calendar, audit logs) in one file.

**Impact**  
- Higher regression risk: unrelated features can be affected by reducer edits.
- Difficult testing: action handling is tightly coupled and large.
- Slower onboarding: developers must parse broad domain logic before making local changes.

**Recommendation**  
Split by domain and move to composable state slices or server-state patterns:
- Keep only shared UI/session state in React context.
- Move entity fetch/mutation state to React Query hooks (already a dependency).
- Introduce domain reducers: `caseReducer`, `documentReducer`, `billingReducer`, etc.

**Example refactor direction**
```ts
// src/state/cases/caseReducer.ts
export type CaseAction =
  | { type: 'ADD_CASE'; payload: Case }
  | { type: 'UPDATE_CASE'; payload: Case }
  | { type: 'DELETE_CASE'; payload: string };

export function caseReducer(state: CaseState, action: CaseAction): CaseState {
  switch (action.type) {
    case 'ADD_CASE':
      return { ...state, cases: [...state.cases, action.payload] };
    // ...
  }
}
```

---

## 2) App-level routing and orchestration complexity

**Problem**  
`src/App.tsx` combines provider composition, routing, section navigation state, route-specific rendering behavior, and special-case navigation (`window.location.href` for design-system route).

**Impact**  
- Reduced readability and difficult route evolution.
- Risky UX behavior (full page reload for one internal route).
- Harder to isolate route-level errors/performance concerns.

**Recommendation**  
- Extract route map into `src/routes/appRoutes.tsx`.
- Remove imperative `window.location.href` and keep SPA navigation consistent.
- Use per-feature route modules (e.g., casesRoutes, documentsRoutes).

**Example refactor direction**
```tsx
// src/routes/AppShellRoutes.tsx
export function AppShellRoutes() {
  return (
    <Routes>
      <Route path="/dashboard" element={<EnhancedDashboardHome />} />
      <Route path="/cases/*" element={<CasesRoutes />} />
      <Route path="/documents/*" element={<DocumentsRoutes />} />
    </Routes>
  );
}
```

---

## 3) Quality gate reliability gap (failing tests)

**Problem**  
Unit test command currently fails (DateRangeFilter tests) while typecheck passes.

**Impact**  
- Reduced confidence in CI signals.
- Developers may ignore failing tests if baseline is already red.
- Accessibility/test contract drift (expected labels no longer match rendered accessible names).

**Recommendation**  
- Stabilize test baseline before feature work.
- Update tests to query by current accessible names OR adjust component labels to expected semantics.
- Add CI policy: block merges on unit test failures and maintain `main` green.

**Example improvement**
```ts
// tests should align to current aria-label
screen.getByLabelText(/Start date for .* filter/i)
```
or
```tsx
// component sets shorter explicit labels
aria-label="Start date"
aria-label="End date"
```

---

## 4) Duplicate Supabase client initialization

**Problem**  
Both `src/utils/supabase.ts` and `src/lib/supabaseClient.ts` create a client with near-identical logic.

**Impact**  
- Drift risk if one file changes env handling and the other does not.
- Confusing import paths for contributors.

**Recommendation**  
- Keep one canonical module (e.g., `src/lib/supabaseClient.ts`).
- Replace all imports with a single alias/path.
- Enforce via lint rule or codeowners convention.

---

## 5) API handler resilience and user messaging

**Problem**  
`api/tyler/attorneys.js` returns HTTP 200 for error conditions and embeds error details in payload strings.

**Impact**  
- Client-side error handling is harder and less standard.
- Monitoring/observability weaker (status code no longer indicates failure).
- End users may receive inconsistent error states.

**Recommendation**  
- Return appropriate status codes (`4xx/5xx`) for failed backend operations.
- Standardize response envelope (`{ error: { code, message }, data }`).
- Log structured errors server-side; show user-safe messages client-side.

---

## 6) Documentation sprawl and onboarding friction

**Problem**  
There are many overlapping setup/deployment docs with similar themes (`DEPLOYMENT_GUIDE.md`, `PRODUCTION-DEPLOYMENT.md`, `deployment/PRODUCTION_DEPLOYMENT.md`, multiple setup guides).

**Impact**  
- New contributors may follow outdated instructions.
- Higher maintenance burden and documentation drift.

**Recommendation**  
- Create a docs index with a “single source of truth” for each process.
- Archive or clearly mark superseded docs.
- Add last-validated date + owner at top of each operational guide.

---

## UX improvement recommendations

1. **Improve accessibility semantics on forms and filters**
   - Ensure visible label + accessible name consistency.
   - Add `aria-live="polite"` for login/auth errors.
   - Standardize error summary patterns for forms.

2. **Improve loading and empty states**
   - Replace repeated inline loading divs with a shared skeleton/loading component.
   - Provide actionable empty states (e.g., “No cases yet — Create case”).

3. **Improve error clarity and recovery**
   - Normalize toast/banner copy and include next-step actions.
   - Avoid exposing raw backend error strings directly to users.

4. **Navigation predictability**
   - Remove route exceptions that trigger full reload and preserve SPA behavior.
   - Add breadcrumb + page title consistency across detail pages.

---

## Code / architecture suggestions

1. **Adopt feature-folder architecture**
   - `src/features/cases`, `src/features/documents`, `src/features/efile`, each with local components/hooks/tests.

2. **Introduce API client layer**
   - Replace direct fetch logic in multiple places with typed service adapters.
   - Centralize auth token handling, retries, and error mapping.

3. **State separation strategy**
   - Server state: React Query.
   - Client-only UI state: Context/Zustand slices.
   - Domain operations: service modules + schema validation.

4. **Testing strategy reset**
   - Tag smoke-critical tests.
   - Keep unit suite green.
   - Add contract tests for API handlers.

---

## Documentation improvements

1. Add `docs/INDEX.md` as canonical entry point:
   - “Start here” onboarding
   - Local setup
   - Environment model (demo vs prod)
   - Deployment runbooks
   - Architecture map

2. Consolidate duplicate guides:
   - Keep one deployment runbook and one setup runbook.
   - Move historical notes to `docs/archive/`.

3. Improve `README.md` onboarding:
   - Include exact `npm` workflow for dev + tests + lint.
   - Link to architecture and troubleshooting pages.

4. Add “definition of done” checklist for PRs:
   - Typecheck, unit tests, accessibility checks, screenshot policy, docs update.

---

## Prioritized action plan for execution

| Priority | Change | Why now | Effort |
|---|---|---|---|
| P0 | Restore test baseline (fix failing unit tests) | Unblocks trusted iteration and CI quality gate | 0.5–1 day |
| P0 | Consolidate Supabase client to single module | Quick win, reduces config drift immediately | 0.5 day |
| P1 | Refactor `App.tsx` routes into modular route files | Major readability + UX behavior improvement | 1–2 days |
| P1 | Split `DataContext` into domain slices / React Query | Largest long-term maintainability gain | 3–5 days |
| P1 | Standardize API error/status handling | Better user feedback and operational visibility | 1–2 days |
| P2 | Create docs index + archive duplicate docs | Improves onboarding and lowers confusion | 1 day |
| P2 | Shared loading/empty/error UX patterns | Raises consistency and accessibility | 1–2 days |
| P3 | Feature-folder migration for major modules | Strategic architecture simplification | 3–7 days (incremental) |

