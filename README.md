<div align="center">
  <img src="ios/Forma/Assets.xcassets/AppIcon.appiconset/Frame%2055(3).png" width="112" alt="Healthmaxxing app icon">

  # Healthmaxxing

  **From a scale reading to a body you can track over time.**

  A SwiftUI iOS client and a Bun/Fastify server that capture Bluetooth smart-scale measurements, derive body composition, and return insights, charts, and structured reports.

  [![Swift](https://img.shields.io/badge/Swift-5-orange.svg?style=flat-square)](https://www.swift.org)
  [![TypeScript](https://img.shields.io/badge/TypeScript-6-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
  [![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20iPadOS-111111.svg?style=flat-square)](https://developer.apple.com/ios/)
  [![Bun](https://img.shields.io/badge/runtime-Bun_1.3-000000?logo=bun&logoColor=white)](https://bun.sh/)
  [![License](https://img.shields.io/badge/license-Apache--2.0%20%2F%20AGPL--3.0-4B5563.svg?style=flat-square)](./LICENSE)
</div>

---

## Overview

Forma, the iOS app, signs the user in, selects a primary profile, and records weight, impedance, and heart rate from a Bluetooth Low Energy scale. Healthmaxxing Server authenticates that session, checks profile ownership, stores the raw reading, derives composition metrics, and queues an insight report. The app polls the job and presents gauges, trend charts, composition maps, and recommendations so a single weigh-in becomes a longitudinal record instead of an isolated number.

The client is SwiftUI with Swift Charts, a dark glass-inspired visual system, Reduce Motion support, and a custom Cormorant Garamond wordmark. The server is TypeScript on Bun and Fastify, with Clerk authentication, PostgreSQL persistence, an external gRPC metrics model, and BullMQ-backed report jobs. Writes go through `/ingest`; profile, trend, and report reads go through `/client`.

## Features

| Area | What the project provides |
| --- | --- |
| **Smart-scale recording** | Forma discovers a BLE scale on service `FFF0` / characteristic `FFF4`, streams weight → impedance → heart rate, validates packets, and submits `POST /ingest/add_measurement/v2` with profile id, weight, heartbeat, and impedance. |
| **Accounts and profiles** | Clerk signs the user in on device and on the server. Healthmaxxing Server upserts the Clerk identity into a local account, supports multiple profiles, and returns `404` when a profile does not belong to the caller. Forma stores the primary profile locally and gates the main tabs on it. |
| **Body composition** | The server persists the raw measurement, then records BMI, fat and lean mass, water and protein percentages, muscle values, BMR, body age, visceral fat, FMI, FFMI, and target weight before the client renders them. |
| **Personal insights** | Forma’s Insights tab shows overview, foundation, progress, recommended focus, physique archetype, and a 0–100 effort score from the latest completed report. |
| **Performance, fat, and muscle** | Performance includes FFMI and excess-fat gauges, an FMI-vs-FFMI quadrant, composition flow, trends, and recomp vectors. Fat and muscle tabs show ratio, mass, visceral/subcutaneous split, skeletal muscle, and bone-mass trends when the report contains them. |
| **Resilient report pipeline** | Ingest returns `jobId` and report ids. The server stores job state as `queued`, `running`, `completed`, or `failed`, retries three times with exponential 2-second backoff, and exposes a wait endpoint that polls once per second (25 s default, 30 s cap). Forma polls that job, supports pull-to-refresh, remembers pending jobs, and caches the latest completed report in protected Application Support storage. |
| **Progress and recovery** | The server returns essentials, weight history, 30-day summaries, circumference history, and trends over `7d`, `30d`, or all history. An authenticated backfill recomputes missing or stale composition rows from stored measurements. |
| **Native client experience** | SwiftUI tabs for Metrics, Record, and Settings; Swift Charts; adaptive system colors; Liquid Glass controls; sound and haptic preferences; iPhone and iPad layouts. |

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

On the server, Fastify schemas validate the main request shapes. Shared pre-handlers authenticate every `/ingest` and `/client` call, upsert the Clerk user into a local account, and scope profile access to that account. Database access goes through Bun’s SQL client and an adapter that rewrites positional query syntax for PostgreSQL; multi-row ownership changes and backfills use transactions. Insight generation is asynchronous: the worker requires persisted structured output before marking a job `completed`, and errors stay on the job row for the client to poll.

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
| **Jobs and metrics** | BullMQ 5.79 with Redis; gRPC `MetricsModel`; LangChain 1.5 with the configured model provider |
| **Testing** | Swift Testing, XCUITest; 26 Bun tests across 5 files plus `tsc --noEmit` |
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

`bun test` is equivalent. The suite has 26 focused tests across 5 files covering PostgreSQL query translation, trend calculations, profile-context formatting, composition-target calculations, metric validation, and insight-report payload normalization. It does not cover Clerk authentication, gRPC calculation, Redis jobs, or HTTP routes end to end.

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

The unit suite covers BLE packet decoding, ordered measurement presentation, idle-timer restoration, chart helpers, and report payload/cache round-trips.

## Roadmap

- Make Forma’s API base URL and Clerk key configurable per build configuration
- Expand supported smart-scale protocols beyond `FFF0` / `FFF4`
- Add Redis and the external metrics service to the local Compose setup
- Recompute composition snapshots automatically when the gRPC calculation step fails
- Add integration tests for profile isolation, ingest → job → report, and iOS polling
- Remove deprecated split registration and `/client/users` after remaining clients migrate
- Add screenshot and UI regression coverage for Forma
- Publish an OpenAPI reference from the existing Fastify route schemas

## License

This combined repository uses two licenses:

- [Healthmaxxing Server (`backend/`)](./backend/LICENSE) and root documentation are [Apache License 2.0](./LICENSE). Use, modification, and redistribution are allowed under the license’s notice and attribution conditions; modified files must be identified.
- [Forma (`ios/`)](./ios/LICENSE) remains [GNU Affero General Public License v3.0](./ios/LICENSE). If you modify and distribute that app—or provide a modified version over a network—you must make the corresponding source available under AGPL-3.0.

---

<div align="center">
  Built with SwiftUI, Bun, and a preference for weigh-ins that turn into a history.
</div>
