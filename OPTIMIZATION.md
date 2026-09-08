# App refinement and optimization

Screen order, tab/navigation structure, report fields, and active API response
contracts are preserved. The refreshed iOS source has Metrics, Record, and Settings;
its current structure is retained. Existing backend changes remain in place.

## Visual system

- Crisp white light surfaces and deep ink dark surfaces with saturated emerald,
  blue, orange, and violet data accents. The faded palette from the first pass is replaced.
- System typography for card titles and metrics; the existing serif wordmark stays.
- Hairline card separation; only hero/floating surfaces retain one shadow.
- One substantial gauge arc with saturated zones, crisp boundary ticks, endpoint
  labels, and a simple white-ringed marker. No extra inner rail. Shared half-circle
  geometry keeps the full stroke and marker inside the card. Category ranges remain
  in the existing legend; interior numeric labels are removed to avoid crowding.
- Stronger chart axes and lines, sparse-history sample dots, emphasized endpoints,
  and a value annotation when inspecting a single series. Existing selection,
  VoiceOver controls, and Dynamic Type behavior remain.
- Excess-fat readouts no longer display a negative amount to lose.

## Work removed from interaction paths

- Cards render immediately without staggered entry states.
- Gauge entry shows the real reading; only subsequent changes animate.
- Full report replacement no longer inherits a container animation.
- Scroll observation publishes the header threshold instead of every offset.
- Charts prepare sorted samples, domains, groups, and date lookups once per input
  construction instead of recomputing them for each mark and scrub update.
- Report payloads parse when the report changes instead of on every property access.
- Successful report checks have a 30-second freshness window. Pull-to-refresh bypasses
  it. Only one latest report ID is requested, and unchanged reports are reused.
- Cancellation and profile/generation checks prevent stale responses updating the UI.
- Shared ephemeral HTTP transport reuses connections without a disk response cache.
- SQL conversion has a bounded 256-entry cache; it stores query text, never results.
- Disconnected long polls stop further queries after the current polling interval.

This follows Apple's guidance to remove repeated calculations from view updates:
[Understanding and improving SwiftUI performance](https://developer.apple.com/documentation/Xcode/understanding-and-improving-swiftui-performance).
Runtime frame-rate or latency gains have not been measured.

## Server surface

18 unused routes and unused WebSocket registration/dependency were removed.
See [the active/retired route inventory](backend/ROUTES.md). Internal worker and
calculation helpers remain. External or older clients using retired paths must migrate.

## Validation

- iOS unsigned generic-device build passed.
- iOS app, unit-test, and UI-test targets compile with `build-for-testing`.
- Native Swift geometry checks pass for gauge stroke bounds and marker alignment
  at five card widths (240–720 points), without a simulator. Regression tests for
  these cases are included in the iOS test target.
- 10 focused Bun checks passed: SQL conversion/cache eviction, composition targets,
  and static route registration contracts. Route checks do not exercise live handlers.
- Full backend typecheck/test execution is blocked by the existing, git-ignored
  `backend/src/calculations/proprietaryMetrics.ts`, absent from this checkout.
  Full tests also require DATABASE_URL to be configured; using a local test URL
  leaves the missing proprietary module as the blocker (14 tests pass; two suites
  cannot load).
- Simulator, visual runtime inspection, and device profiling were not run.
