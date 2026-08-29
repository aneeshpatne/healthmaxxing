<div align="center">
  <img src="ios/Forma/Assets.xcassets/AppIcon.appiconset/Frame%2055(3).png" width="112" alt="Healthmaxxing app icon">

  # Healthmaxxing

  **From a scale reading to a body you can track over time.**

  A SwiftUI iOS client and Bun/Fastify server that capture Bluetooth smart-scale measurements, derive body composition over gRPC, and fan each reading into asynchronous insight reports with gauges, trend charts, and structured JSON-LD outputs.

  [![Swift](https://img.shields.io/badge/Swift-5-orange.svg?style=flat-square)](https://www.swift.org)
  [![TypeScript](https://img.shields.io/badge/TypeScript-6-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
  [![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20iPadOS-111111.svg?style=flat-square)](https://developer.apple.com/ios/)
  [![Bun](https://img.shields.io/badge/runtime-Bun_1.3-000000?logo=bun&logoColor=white)](https://bun.sh/)
  [![License](https://img.shields.io/badge/license-Apache--2.0%20%2F%20AGPL--3.0-4B5563.svg?style=flat-square)](./LICENSE)

  [![reports generated](https://img.shields.io/badge/reports_generated-736-111111.svg?style=flat-square)](#project-impact)
  [![API handlers](https://img.shields.io/badge/HTTP_handlers-27-111111.svg?style=flat-square)](#engineering-highlights)
  [![automated tests](https://img.shields.io/badge/automated_tests-53-111111.svg?style=flat-square)](#running-tests)
  [![scale measurements](https://img.shields.io/badge/scale_measurements-185-111111.svg?style=flat-square)](#project-impact)
</div>

---

## Overview

Forma, the iOS app, signs the user in, selects a primary profile, and records weight, impedance, and heart rate from a Bluetooth Low Energy scale. Healthmaxxing Server authenticates that session, checks profile ownership, stores the raw reading, derives composition metrics through an external gRPC `MetricsModel`, and queues a BullMQ insight job on Redis. The app long-polls the job and presents gauges, trend charts, composition maps, and recommendations so a single weigh-in becomes a longitudinal record instead of an isolated number.

In the live PostgreSQL dataset (queried August 27, 2026), that pipeline has turned **185 scale measurements** spanning **April 20–August 27, 2026** into **736 reports**, **185 body-composition snapshots**, and **124 structured JSON-LD insight payloads**, across **27 HTTP handlers**, **30 tables**, and **15 applied migrations**. Insight jobs retry **3 times** with exponential **2-second** backoff; clients wait with a **1-second** poll interval, **25-second** default timeout, and **30-second** hard cap.

The client is SwiftUI with Swift Charts, a dark glass-inspired visual system, Reduce Motion support, and a custom Cormorant Garamond wordmark. The server is TypeScript on Bun and Fastify, with Clerk authentication, PostgreSQL persistence, LangChain-backed report generation, and persisted job states (`queued` → `running` → `completed` / `failed`). Writes go through `/ingest`; profile, trend, and report reads go through `/client`.

## Engineering highlights

Concrete facts from the implementation and the live database. Dataset counts describe the current personal dataset, not production multi-tenant adoption.

| Area | Evidence |
| --- | --- |
| **API surface** | **27** registered HTTP handlers: **22** `/client`, **4** `/ingest`, and **1** `GET /health` database probe. |
| **Async report pipeline** | BullMQ queue `jobs` with **3** attempts, exponential backoff starting at **2,000 ms**, `removeOnComplete: 100`, and `removeOnFail: 500`. |
| **Client wait contract** | Long-poll wait endpoint checks every **1 s**, defaults to **25 s**, and clamps `timeoutMs` to **30 s**. |
| **Reliability controls** | **10 MB** Fastify body limit; per-profile measurement idempotency keys; stale insight jobs fail after **30 minutes**; in-flight jobs are failed on process startup; graceful `SIGINT`/`SIGTERM` shutdown closes API, worker, and DB. |
| **Data model** | **30** PostgreSQL tables, **68** indexes (**29** secondary `idx_*`), **15** applied migrations (**13** SQL files in this checkout, plus **2** historical migrations retained in the live DB). |
| **Composition depth** | Each snapshot stores **19** trendable body-composition factors across periods `7d`, `30d`, and `all`, plus FMI/FFMI and target-composition calculations. |
| **Report fan-out** | One ingested measurement can produce performance, fat, muscle, and profile-insight report rows—about **4 reports per reading** in the live set (**736 / 185 ≈ 3.98**). |
| **Insight outcomes** | **126** completed and **52** failed profile-insight jobs (**70.8%** completion of **178** insight reports); **124** structured JSON-LD outputs persisted for client retrieval. |
| **Token efficiency** | Jul 19 schema streamline cut structured cards **42→20 (−52%)** and observed mean total tokens / run **24,997→10,356 (−59%)**; median total **26,507→8,136 (−69%)**. See [Engineering outcomes](#engineering-outcomes). |
| **Integrations** | Clerk auth, Redis/BullMQ workers, external gRPC `MetricsModel`, LangChain report agent with **24 h** prompt-cache retention, and optional document conversion via gRPC MarkItDown. |
| **Verification** | **53** automated tests: **26** Bun tests across **5** files and **27** iOS tests (**20** Swift Testing unit cases + **7** XCUITest cases), plus `tsc --noEmit`. |

## Project impact

The following snapshot was read from the live PostgreSQL database on **August 27, 2026**.

- **Turned 185 scale readings into a longitudinal health product** across four months of history, from April 20 through August 27, 2026 (~**1.4 readings/day** over **130** days).
- **Generated 736 reports** across performance, fat, muscle, profile insights, and imported health data from a single measurement pipeline.
- **Extracted 38 structured observations** from **3** imported health reports, organized across **8** report sections and **13** catalogued observation fields.
- **Persisted 185 body-composition snapshots and 185 FMI/FFMI rows**, making each check-in useful for historical comparison rather than just a one-time readout.
- **Completed 126 insight jobs and persisted 124 structured JSON-LD outputs** for reliable client retrieval and later inspection (**52** failed jobs remain observable in the database).
- **Synced 14 workouts and 516 report comments** while keeping the full record in a **13 MB** PostgreSQL database (**2,151** rows across **30** tables; **2** accounts / **3** profiles).

### Dataset detail

| Metric | Count |
| --- | ---: |
| **Database rows** | 2,151 |
| **Database size** | 13 MB |
| **Tables / indexes** | 30 / 68 |
| **Applied migrations** | 15 |
| **Scale measurements** | 185 |
| **Body-composition snapshots** | 185 |
| **FMI / FFMI rows** | 185 |
| **Reports generated** | 736 |
| **Performance / fat / muscle reports** | 185 each |
| **Profile-insight reports** | 178 |
| **Insight jobs completed / failed** | 126 / 52 |
| **Structured JSON-LD outputs** | 124 |
| **Report comments** | 516 |
| **Workouts synced** | 14 |
| **Imported health reports** | 3 |
| **Extracted observations** | 38 |
| **Active history** | 4 months (Apr 20–Aug 27, 2026) |

## Engineering outcomes

Aggregate improvements since inception across both packages in this monorepo: **Healthmaxxing Server** (`backend/`, from **2026-05-09**) and **Forma** (`ios/`, from **2026-06-19**). Dataset and token figures describe the personal/dev workload and observed worker logs — not production multi-tenant traffic or a controlled A/B on identical prompts.

### Cross-stack ROI

| Metric | Before → After | Delta |
| --- | --- | --- |
| Insight report structured cards | **42 → 20** top-level cards | **−52%** (Jul 19, 2026 schema streamline) |
| Insights client cards (schema v2) | Broad narrative set → **3** (`factor` / `key_trend` / `progress`) | Lean coach brief Forma renders today |
| Mean tokens / insight run | **24,997 → 10,356** | **−59%** (48 runs before vs 100 after Jul 19) |
| Mean input tokens / run | **18,944 → 7,969** | **−58%** |
| Median total tokens / run | **26,507 → 8,136** | **−69%** |
| Measurement fan-out | 1 reading → composition + FMI/FFMI + perf/fat/muscle + insight job | **~4 reports / reading** in the live set (**736 / 185 ≈ 3.98**) |

### Report schema compression (`backend/`)

Card counts are the top-level keys under `insights`, `performance`, `fat`, and `muscle` in `backend/src/ai/toolsNew.ts`.

| Schema revision | Date | Total cards | Insights | Performance | Fat | Muscle |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Before streamline | 2026-07-19 parent | 42 | 13 | 12 | 9 | 8 |
| After streamline | 2026-07-19 | 20 | 7 | 6 | 5 | 2 |
| Current `HEAD` (schema v2) | post Aug slims | 20 | 3 | 6 | 6 | 5 |

July 19 cut the structured output surface in half. Later work kept the same **20**-card budget while reshaping Insights into the three-card layout and consolidating the agent `userContext` blob (Aug 9).

### Observed token spend (`backend/` worker logs)

Parsed from `[agentOrchestratorNew] total token spend` lines in the local launchd server log, timestamped from adjacent Pino records. The Jul 19 change day is excluded.

| Cohort | Runs | Mean input | Mean output | Mean total | Median total |
| --- | ---: | ---: | ---: | ---: | ---: |
| Before streamline (Jul 2–18, 2026) | 48 | 18,944 | 6,053 | 24,997 | 26,507 |
| After streamline (Jul 20–Aug 29, 2026) | 100 | 7,969 | 2,387 | 10,356 | 8,136 |

The immediate post-streamline window (Jul 20–Aug 8) was leanest—mean total about **8,041** across **43** runs—before later schema-v2 and prompt iterations raised August averages slightly while staying well below the pre-streamline baseline.

### Server reliability & API surface (`backend/`)

| Control | Metric |
| --- | --- |
| HTTP handlers | **27** (**22** `/client`, **4** `/ingest`, **1** `/health`) |
| Migrations | **13** SQL files in checkout; **15** applied in the live DB |
| Initial schema → now | **27** tables at birth → **30** tables / **68** indexes live |
| Request body limit | **10 MB** |
| Report retries | **3** attempts, exponential backoff from **2,000 ms** |
| Stale job expiry | fail active jobs older than **30 minutes** |
| Startup recovery | fail in-flight `pending`/`queued`/`running` jobs on process start |
| Client wait contract | poll **1 s**; default **25 s**; hard cap **30 s** |
| Idempotency | per-profile measurement keys; replay returns `replayed: true` |
| Auth | Clerk on every `/ingest` and `/client` route; foreign profile → **404** |
| Deprecated routes sunset | **2026-06-30** (split registration, `GET /client/users`) |
| Source scale | **36** TypeScript files under `backend/src/` (~**11.0k** LOC) |
| Bun tests | **26** across **5** files (+ `tsc --noEmit`) |

### Forma client growth & product surface (`ios/`)

| Metric | Value |
| --- | --- |
| App Swift files | **36** under `ios/Forma/` (~**9.6k** LOC) |
| Design system | `FormaTheme.swift` ≈ **1,991** LOC; shared motion, spacing, typography, gauges, charts |
| Root tabs | **3** — Metrics, Record, Settings (Workouts / Vitals placeholder shells removed) |
| Metrics sub-tabs | **4** — Insights, Performance, Fat, Muscle |
| Typed API routes | **8** (profiles ×3, ingest ×1, insight jobs/reports ×4) |
| BLE contract | service **FFF0**, notify **FFF4**; weight → impedance → heart rate with checksum validation |
| Report cache | per-profile JSON in Application Support with **atomic** + **completeFileProtection** writes |
| Wait polling | `timeoutMs` default **25,000**, clamped to **≤30,000** |
| Lazy metric lists | **6** `LazyVStack` sites across Insights / Fat / Muscle (and related chrome) |
| Motion language | `FormaMotion.tap` **100 ms**, `fast` **160 ms**, `standard` **280 ms**, plus selection / data-reveal / brand tokens |
| Reduce Motion | **14** `accessibilityReduceMotion` call sites |
| Automation hooks | **13** `accessibilityIdentifier` values |
| Unit tests | **20** Swift Testing `@Test` cases |
| UI tests | **7** XCUITest methods (including launch-performance harness) |
| Combined verification | **53** automated tests (26 Bun + 27 iOS) |

### Timeline of high-signal improvements

| When | Package | Outcome |
| --- | --- | --- |
| **2026-05-09** | Server | Fastify ingest / bootstrap |
| **2026-06-19** | Client | Forma scaffold |
| **2026-06-29–30** | Client | Clerk auth, BLE, networking, profiles, settings |
| **2026-07-01** | Client | Insight payload + `MetricsReportStore` |
| **2026-07-02–18** | Server | Pre-sweep agent spend ≈ **25k** tokens / run |
| **2026-07-11–14** | Client | Design system; disk report cache; staged Record flow |
| **2026-07-19** | Server | Cards **42→20**; token drop begins |
| **2026-07-20** | Client | API harden + lazy Fat/Muscle charts + cheaper series updates |
| **2026-08-03–05** | Client | Mint palette; native motion tokens; drop Workouts/Vitals shells |
| **2026-08-09** | Both | Consolidated `userContext`; Insights **3-card** shape; stale-job + startup fail |
| **2026-08-27** | Server | Live DB snapshot in Project impact (**185** measurements, **736** reports) |

## Features

| Area | What the project provides |
| --- | --- |
| **Smart-scale recording** | Forma discovers a BLE scale on service `FFF0` / characteristic `FFF4`, streams weight → impedance → heart rate, validates packets, and submits `POST /ingest/add_measurement/v2` with profile id, weight, heartbeat, impedance, and an optional `Idempotency-Key`. |
| **Accounts and profiles** | Clerk signs the user in on device and on the server. Healthmaxxing Server upserts the Clerk identity into a local account, supports multiple profiles, and returns `404` when a profile does not belong to the caller. Forma stores the primary profile locally and gates the main tabs on it. |
| **Body composition** | The server persists the raw measurement, then records BMI, fat and lean mass, water and protein percentages, muscle values, BMR, body age, visceral fat, FMI, FFMI, and target weight before the client renders them—**19** named factors are available for trend queries. |
| **Personal insights** | Forma’s Insights tab shows overview, foundation, progress, recommended focus, physique archetype, and a 0–100 effort score from the latest completed report. |
| **Performance, fat, and muscle** | Performance includes FFMI and excess-fat gauges, an FMI-vs-FFMI quadrant, composition flow, trends, and recomp vectors. Fat and muscle tabs show ratio, mass, visceral/subcutaneous split, skeletal muscle, and bone-mass trends when the report contains them. |
| **Resilient report pipeline** | Ingest returns `jobId` and report ids. The server stores job state as `queued`, `running`, `completed`, or `failed`, retries **three** times with exponential **2-second** backoff, expires jobs still pending after **30 minutes**, and exposes a wait endpoint that polls once per second (**25 s** default, **30 s** cap). Forma polls that job, supports pull-to-refresh, remembers pending jobs, and caches the latest completed report in protected Application Support storage. |
| **Progress and recovery** | The server returns essentials, weight history, 30-day summaries, circumference history (up to **9** sites), and trends over `7d`, `30d`, or all history. An authenticated backfill recomputes missing or stale composition rows from stored measurements. |
| **Native client experience** | SwiftUI tabs for Metrics, Record, and Settings; Swift Charts; adaptive system colors; Liquid Glass controls; sound and haptic preferences; iPhone and iPad layouts. Forma’s networking layer currently ships **8** typed `APIRequest` clients for profiles, ingest, and insight-job polling. |

> [!NOTE]
> Recording, Clerk authentication, profiles, settings, metrics dashboards, measurement ingestion, composition snapshots, and queued insight reports are implemented. Workout upsert exists on Healthmaxxing Server but is not exposed in Forma; the Workouts and Vitals tabs were removed. The `MetricsModel` gRPC calculator is a separate service and is not in this repository. Redis is required for report jobs and is not defined in `backend/docker-compose.yml`. Legacy split profile-registration routes and `GET /client/users` are deprecated, with a June 30, 2026 sunset; Forma already uses `/client/register/profiles/v2` and `/client/profiles`.

## From scale to insight

```mermaid
flowchart TB
    U([User])
    U --> A[Clerk sign-in]
    A --> P[Primary profile]
    P --> R[Forma Record]
    R --> B{BLE scale}
    B --> W[Weight]
    W --> I[Impedance]
    I --> H[Heart rate]
    H --> API["POST /ingest/<br/>add_measurement/v2"]
    API --> D[(Raw measurement)]
    D --> E[gRPC MetricsModel]
    E --> F[Derived composition]
    F --> Q[Redis / BullMQ]
    Q --> J[Report worker]
    J --> C[(Insight report)]
    C --> W2["GET .../jobs/{id}/wait"]
    W2 -->|pending / running| W2
    W2 -->|completed| UI[Forma Metrics]
```

Forma keeps each scale stage on screen even when packets arrive almost together, leases the idle timer during a reading, and can retry a failed submit without taking another measurement. Healthmaxxing Server writes the raw reading before calling the metrics service, so a calculation failure can leave a measurement without a snapshot; the backfill endpoint recomputes that history. The iOS wait request sends `timeoutMs` clamped to 30 seconds; if the job is still `queued` or `running`, `MetricsReportStore` loops until completion, failure, or cancellation, then caches the payload for the primary profile.

## Product map

```mermaid
flowchart TB
    P[Health profile]

    subgraph IN[Inputs]
        direction TB
        IN1[Scale readings]
        IN2[Body measurements]
        IN3[Workouts on the server]
    end

    subgraph CO[Composition]
        direction TB
        CO1[Fat and lean mass]
        CO2[Muscle and hydration]
        CO3[FMI and FFMI]
    end

    subgraph PR[Progress]
        direction TB
        PR1[Weight summary]
        PR2[7d / 30d / all trends]
        PR3[Effort score]
    end

    subgraph RP[Reports]
        direction TB
        RP1[Insights]
        RP2[Performance]
        RP3[Fat]
        RP4[Muscle]
    end

    P --> IN
    IN --> CO
    CO --> PR
    PR --> RP
```

## Architecture

```mermaid
flowchart TB
    subgraph IOS["Forma — ios/"]
        direction TB
        APP[FormaApp] --> AUTH{Authenticated?}
        AUTH -->|No| SIGNIN[ClerkSignInView]
        AUTH -->|Yes| GATE[Primary profile gate]
        GATE --> TABS["Metrics / Record / Settings"]
        TABS --> BLE[ScaleBLEManager]
        TABS --> STORE[MetricsReportStore]
        STORE --> CLIENT[APIClient]
        CLIENT --> TOKEN[ClerkTokenProvider]
    end

    subgraph SERVER["Healthmaxxing Server"]
        direction TB
        FASTIFY[Fastify app] --> INGEST["/ingest"]
        FASTIFY --> CLIENTAPI["/client"]
        FASTIFY --> HEALTH["/health"]
        INGEST --> MW[Clerk middleware]
        CLIENTAPI --> MW
        MW --> CMD[Database commands]
        INGEST --> QUEUE[BullMQ worker]
    end

    subgraph INFRA[Infrastructure]
        direction TB
        SCALE[BLE scale]
        CLERK[Clerk]
        GRPC[MetricsModel gRPC]
        REDIS[(Redis)]
        PG[(PostgreSQL 17)]
        LLM[Report model provider]
    end

    IOS --> SERVER
    SERVER --> INFRA
    BLE --> SCALE
    CLIENT --> INGEST
    CLIENT --> CLIENTAPI
    TOKEN --> CLERK
    MW --> CLERK
    INGEST --> GRPC
    CMD --> PG
    QUEUE --> REDIS
    QUEUE --> LLM
    QUEUE --> CMD
```

Forma networking is request-driven: each endpoint conforms to `APIRequest`, and `APIClient` builds `APIConfig.baseURL` + path, attaches a Clerk bearer token, encodes JSON, and decodes the typed response. UI state stays on the main actor; `InsightReportPayload` turns stored report JSON into presentation sections.

On the server, Fastify schemas validate the main request shapes under a **10 MB** body limit. Shared pre-handlers authenticate every `/ingest` and `/client` call, upsert the Clerk user into a local account, and scope profile access to that account. Database access goes through Bun’s SQL client and an adapter that rewrites positional query syntax for PostgreSQL; multi-row ownership changes and backfills use transactions. Insight generation is asynchronous: the worker requires persisted structured output before marking a job `completed`, retries failed generations up to **3** times, and errors stay on the job row for the client to poll. Local PostgreSQL is managed by Docker Compose with a `pg_isready` health check every **2 s** (timeout **3 s**, **20** retries) and `restart: unless-stopped`.

The two trees are independent runtimes. Forma currently targets the hosted API at `https://forma.aneeshpatne.com`; pointing it at a local Healthmaxxing Server means changing `ios/Forma/Networking/APIConfig.swift`.

## Tech stack

| Layer | Technology |
| --- | --- |
| **Languages** | Swift 5 (approachable concurrency, main-actor isolation); TypeScript 6 with strict compiler checks |
| **Client UI** | SwiftUI, Swift Charts, custom SwiftUI shapes |
| **Server runtime** | [Bun](https://bun.sh/) 1.3, [Fastify](https://fastify.dev/) 5.9, `@fastify/websocket` |
| **Authentication** | [ClerkKit / ClerkKitUI](https://github.com/clerk/clerk-ios) 1.2.6+ on device; `@clerk/backend` and `@clerk/fastify` on the server |
| **Networking** | URLSession, async/await, Codable; HTTP JSON to `/ingest` and `/client` |
| **Device integration** | CoreBluetooth (`FFF0` / `FFF4`) |
| **Persistence** | UserDefaults and protected JSON files on device; PostgreSQL 17 with Bun `SQL` |
| **Jobs and metrics** | BullMQ 5.79 with Redis; gRPC `MetricsModel`; LangChain 1.5 with the configured model provider (**24 h** prompt-cache retention) |
| **Testing** | Swift Testing, XCUITest; **26** Bun tests across **5** files plus `tsc --noEmit`; **20** iOS unit tests and **7** UI tests |
| **Local operations** | Docker Compose for PostgreSQL 17; optional macOS `launchd` agent for the server |

## Project structure

```text
.
├── ios/                              # Forma iOS client
│   ├── Forma/
│   │   ├── FormaApp.swift            # App entry and Clerk setup
│   │   ├── ContentView.swift         # Auth and primary-profile gate
│   │   ├── SwiftUIView.swift         # Metrics / Record / Settings tabs
│   │   ├── RecordView.swift          # Guided BLE measurement flow
│   │   ├── ScaleBLEManager.swift     # Scale discovery and notifications
│   │   ├── Profiles.swift            # Profile list and create/edit
│   │   ├── Metrics/                  # Insights, Performance, Fat, Muscle
│   │   └── Networking/
│   │       ├── APIClient.swift       # Shared authenticated HTTP client
│   │       ├── APIConfig.swift       # API base URL
│   │       ├── Measurements/         # POST /ingest/add_measurement/v2
│   │       ├── Profiles/             # /client profile routes
│   │       └── Insights/             # Job polling, payloads, cache
│   ├── FormaTests/                   # Decoder, record-flow, report tests
│   └── Forma.xcodeproj
├── backend/                          # Healthmaxxing Server
│   ├── src/
│   │   ├── app.ts                    # Fastify plugins, routes, /health
│   │   ├── main.ts                   # API + report worker
│   │   ├── routes/ingest.ts          # Measurement, workout, backfill writes
│   │   ├── routes/client.ts          # Profiles, summaries, trends, reports
│   │   ├── middleware/auth.ts        # Clerk auth and account resolution
│   │   ├── bull/                     # Redis queue and worker
│   │   └── db/                       # SQL client, commands, migrations
│   ├── migrations/                   # PostgreSQL schema history
│   ├── proto/                        # gRPC service contracts
│   └── docker-compose.yml            # Local PostgreSQL 17
└── README.md
```

Standalone histories still live at [`aneeshpatne/Forma_IOS`](https://github.com/aneeshpatne/Forma_IOS) and [`aneeshpatne/healthmaxxing-server`](https://github.com/aneeshpatne/healthmaxxing-server). Package-level detail is in [`ios/README.md`](./ios/README.md) and [`backend/README.md`](./backend/README.md).

## Requirements

**Forma (ios/)**

- macOS with Xcode 26.5 or newer
- iOS / iPadOS 26.5+ deployment target
- A Clerk application accepted by the configured publishable key
- Network access to Healthmaxxing Server for profiles, ingest, and reports
- A compatible BLE scale exposing service `FFF0` and notify characteristic `FFF4` for live recordings

**Healthmaxxing Server (backend/)**

- Bun 1.3; currently validated with Bun 1.3.14
- Docker and Docker Compose for the bundled PostgreSQL 17 service
- A Clerk application and `CLERK_SECRET_KEY`
- A reachable `proto/metrics_model.proto` implementation; default `localhost:50054`
- Redis for report jobs; default `redis://localhost:6379` (not in Compose)
- `OPENAI_API_KEY` for the configured structured-report model
- Network access for dependency install, Clerk verification, and model calls

Analytics screens run in the iOS Simulator; live scale capture needs a physical iPhone or iPad with Bluetooth. The Bun API runs on macOS or Linux; the `launchd` installer is macOS-only. Production must supply managed PostgreSQL, Redis, Clerk, metrics-service, and model-provider configuration rather than the local defaults.

## Getting started

1. Clone this repository.

   ```bash
   git clone https://github.com/aneeshpatne/healthmaxxing.git
   cd healthmaxxing
   ```

2. Install and configure Healthmaxxing Server.

   ```bash
   cd backend
   bun install
   cp .env.example .env
   ```

   Set at least:

   ```dotenv
   DATABASE_URL=postgres://healthmaxxing:healthmaxxing@127.0.0.1:5432/healthmaxxing
   CLERK_SECRET_KEY=replace-with-a-clerk-secret
   METRICS_MODEL_ADDRESS=localhost:50054
   REDIS_URL=redis://localhost:6379
   OPENAI_API_KEY=replace-with-an-openai-key
   PORT=3030
   HOST=0.0.0.0
   ```

3. Start PostgreSQL and apply migrations.

   ```bash
   bun run db:up
   bun run db:migrate
   ```

4. Start Redis and the external `MetricsModel` gRPC service so they match `.env`. Then run the API and report worker.

   ```bash
   bun run start
   ```

   API-only (no worker): `bun run server`. Migrations also run before either process listens. Check `http://localhost:3030/health`.

5. Open Forma.

   ```bash
   open ios/Forma.xcodeproj
   ```

   Swift Package Manager resolves Clerk. Review `ios/Forma/ClerkConfig.swift`, `ios/Forma/Networking/APIConfig.swift`, and `ios/Forma/Info.plist` (Bluetooth usage string and Clerk callback scheme). To hit a local server, point `APIConfig.baseURL` at that host instead of `https://forma.aneeshpatne.com`.

6. Select an iOS 26.5+ simulator or device, run with **⌘R**, sign in, and create a primary profile. A primary profile is required before the main tabs.

> [!IMPORTANT]
> Forma ships pointed at the hosted Healthmaxxing API and a Clerk test publishable key. `backend/.env.example` and Compose use local database credentials. Replace those values before distributing a fork, keep provider keys out of version control, and do not commit a populated `.env`.

## Running tests

**Healthmaxxing Server**

```bash
cd backend
bun run test
bun run typecheck
```

`bun test` is equivalent. The suite has **26** focused tests across **5** files covering PostgreSQL query translation, trend calculations, profile-context formatting, composition-target calculations, metric validation, and insight-report payload normalization. It does not cover Clerk authentication, gRPC calculation, Redis jobs, or HTTP routes end to end.

**Forma**

Run `FormaTests` and `FormaUITests` from Xcode with **⌘U**, or:

```bash
cd ios
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild test \
  -project Forma.xcodeproj \
  -scheme Forma \
  -destination 'platform=iOS Simulator,name=<your simulator>'
```

The unit suite contains **20** Swift Testing cases covering BLE packet decoding, ordered measurement presentation, idle-timer restoration, chart helpers, and report payload/cache round-trips. The UI suite adds **7** XCUITest cases for tab shells, metrics loading/error states, and launch performance measurement. Combined with the Bun suite, the monorepo ships **53** automated tests.

## Roadmap

- Make Forma’s API base URL and Clerk key configurable per build configuration
- Expand supported smart-scale protocols beyond `FFF0` / `FFF4`
- Add Redis and the external metrics service to the local Compose setup
- Recompute composition snapshots automatically when the gRPC calculation step fails
- Add integration tests for profile isolation, ingest → job → report, and iOS polling
- Remove deprecated split registration and `/client/users` after remaining clients migrate
- Add screenshot and UI regression coverage for Forma
- Publish an OpenAPI reference from the existing Fastify route schemas
- Capture API latency percentiles and report-job duration histograms in production observability

## License

This combined repository uses two licenses:

- [Healthmaxxing Server (`backend/`)](./backend/LICENSE) and root documentation are [Apache License 2.0](./LICENSE). Use, modification, and redistribution are allowed under the license’s notice and attribution conditions; modified files must be identified.
- [Forma (`ios/`)](./ios/LICENSE) remains [GNU Affero General Public License v3.0](./ios/LICENSE). If you modify and distribute that app—or provide a modified version over a network—you must make the corresponding source available under AGPL-3.0.

---

<div align="center">
  Built with SwiftUI, Bun, and a preference for weigh-ins that turn into a history.
</div>
