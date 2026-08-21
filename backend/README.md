<div align="center">

# Healthmaxxing

**Turn health measurements into a clear view of progress.**

An authenticated health-data service that converts scale readings, body measurements, and workouts into body-composition history, progress summaries, and structured insight reports.

[![TypeScript](https://img.shields.io/badge/TypeScript-6-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Bun](https://img.shields.io/badge/runtime-Bun_1.3-000000?logo=bun&logoColor=white)](https://bun.sh/)
[![Fastify](https://img.shields.io/badge/Fastify-5.9-000000?logo=fastify&logoColor=white)](https://fastify.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/license-Apache_2.0-D22128)](./LICENSE)

</div>

---

## Overview

Healthmaxxing receives authenticated profile data, smart-scale measurements, circumference measurements, and workout records. It validates profile ownership, stores each input, derives body-composition metrics, and returns snapshots, trends, scores, and generated reports that help a client show how a person's measurements are changing over time.

The service is a TypeScript application running on Bun and Fastify, with Clerk authentication, PostgreSQL persistence, gRPC-based metric calculation, and BullMQ-backed report jobs. Its API is divided into write-oriented `/ingest` routes and client-facing `/client` routes; startup migrations, UUIDv7 identifiers, strict account scoping, and persisted job states keep the data flow explicit.

## Proof points

The repository is a personal project rather than a production-traffic system, so the most honest scale signals are the exercised data model and the constraints enforced in code. The figures below were read from the configured PostgreSQL database on August 21, 2026; they are development-dataset counts, not claims about users or production adoption.

| Scope | Concrete fact |
| --- | --- |
| **Data volume** | 2 accounts, 3 profiles, 174 scale measurements, 1 body-measurement record, and 14 workouts. |
| **Derived history** | 174 body-composition snapshots, 174 FMI/FFMI rows, and 174 each of performance, fat, and muscle report snapshots. |
| **Insight pipeline** | 167 profile-insight reports: 115 completed and 52 failed; 113 structured JSON-LD outputs are persisted. |
| **Report detail** | 3 imported health reports, 8 sections, 38 observations, and 13 catalogued observation fields. |
| **Database footprint** | PostgreSQL reports a 13 MB database; measurements span April 20–August 21, 2026. |
| **API surface** | 27 registered HTTP handlers: 22 client routes, 4 ingest routes, and 1 database health check. |
| **Schema evolution** | 27 initial tables and 17 initial indexes; 15 migrations are applied in the live database, including 2 historical migrations not present in the current checkout. |
| **Reliability controls** | A 10 MB request cap, per-profile measurement idempotency keys, persisted calculation/report states, three report attempts with exponential 2-second backoff, and row-count verification for SQLite imports. |
| **Async behavior** | Insight jobs are polled at 1-second intervals, with a 25-second default wait and a hard 30-second maximum. |
| **Verification** | 26 focused Bun tests across 5 test files, plus a strict TypeScript typecheck command. |

The older `mydb.sqlite` file remains a legacy export; its 29 measurements are not used as the current scale figure. The live PostgreSQL database is the source of truth for the runtime counts above.

### Impact in practice

- **Turns isolated readings into a longitudinal product surface.** The live dataset spans April 20–August 21, 2026, with 174 scale measurements feeding 174 body-composition snapshots and matching performance, fat, and muscle reports.
- **Makes one ingestion event useful across the client experience.** A stored measurement can fan out into derived BMI, fat, lean-mass, hydration, muscle, FMI, and FFMI values, then create a queued profile-insight job for asynchronous interpretation.
- **Keeps model-dependent work observable and recoverable.** The database records explicit job outcomes—115 completed and 52 failed profile-insight jobs—while persisting 113 structured JSON-LD outputs for later retrieval instead of making report generation an opaque request-time side effect.
- **Supports more than a single happy-path profile.** The current PostgreSQL data includes 2 accounts and 3 profiles, while shared authentication middleware and profile ownership checks keep profile-scoped reads and writes isolated.
- **Preserves delivery safety as the system evolves.** Per-profile measurement idempotency, persisted calculation status, queued retries with exponential backoff, stale-job cleanup, and 15 applied migrations protect the path from raw input to client-visible insight.

## Features

| Area | What the project provides |
| --- | --- |
| **Accounts and profiles** | Resolves Clerk users to local accounts, supports multiple profiles per account, assigns a primary profile, and keeps profile metadata and targets editable. |
| **Scale ingestion** | Accepts weight, heart rate, and impedance readings, then stores the raw measurement before calculating the corresponding composition snapshot. |
| **Body composition** | Records BMI, body-fat and lean-mass values, water and protein percentages, muscle measurements, BMR, body age, visceral fat, FMI, FFMI, and target weight. |
| **Progress tracking** | Returns essentials, weight history, 30-day summaries, circumference history, and metric trends over `7d`, `30d`, or the full available history. |
| **Workout sync** | Upserts workouts by their source identifier and preserves timing, energy, heart-rate, distance, cadence, environment, metadata, and the original payload. |
| **Insight reports** | Creates performance, fat, muscle, and profile-insight snapshots for a measurement and exposes recent reports, active jobs, completion states, and report lookup endpoints. |
| **Historical recovery** | Recalculates missing or stale composition rows from stored measurements and provides SQLite-to-PostgreSQL import and row-count verification scripts. |
| **Operations** | Applies ordered SQL migrations before listening, reports PostgreSQL availability through `GET /health`, shuts down cleanly on termination signals, and includes optional per-user `launchd` automation. |

> [!NOTE]
> Profile management, measurement and workout ingestion, body-composition queries, PostgreSQL migration, and queued insight reports are implemented. The metrics calculator is a separate gRPC service and is not included in this repository. Legacy split profile-registration routes and `GET /client/users` are deprecated with a June 30, 2026 sunset date; `/client/register/profiles/v2` and `GET /client/profiles` are their replacements.

## From measurement to insight

```mermaid
flowchart LR
    A[Client measurement] --> B[Clerk authentication]
    B --> C[Profile ownership check]
    C --> D[(Raw measurement)]
    D --> E[gRPC metric model]
    E --> F[Derived metrics]
    F --> G[(Snapshot reports)]
    G --> H[Redis job queue]
    H --> I[Report worker]
    I --> J[(Completed insight)]
    J --> K[Client report APIs]
    K -->|queued or running| K
```

Measurement ingestion persists the raw reading before calling the metric service, so a downstream calculation failure can leave a reading without its derived snapshot; the authenticated backfill endpoint can recompute that history. Report state is stored as `queued`, `running`, `completed`, or `failed`. The wait endpoint checks once per second, defaults to 25 seconds, and caps a request at 30 seconds; clients can also list active or recent jobs and retry later.

## Product map

```mermaid
flowchart TD
    P[Health profile]
    P --> I[Inputs]
    P --> C[Composition]
    P --> T[Progress]
    P --> R[Reports]

    I --> I1[Scale readings]
    I --> I2[Body measurements]
    I --> I3[Workouts]

    C --> C1[Fat and lean mass]
    C --> C2[Muscle and hydration]
    C --> C3[FMI and FFMI]

    T --> T1[Weight summary]
    T --> T2[7d / 30d / all trends]
    T --> T3[Forma score]

    R --> R1[Essentials]
    R --> R2[Performance]
    R --> R3[Fat and muscle]
    R --> R4[Profile insights]
```

## Architecture

```mermaid
flowchart TB
    subgraph API[Application]
        APP[Fastify application]
        INGEST["/ingest routes"]
        CLIENT["/client routes"]
        HEALTH["/health"]
        APP --> INGEST
        APP --> CLIENT
        APP --> HEALTH
    end

    subgraph DOMAIN[Domain and services]
        AUTH[Authentication middleware]
        COMMANDS[Database commands]
        CALC[Summary calculations]
        QUEUE[Report queue and worker]
        MIGRATE[Migration runner]
        INGEST --> AUTH
        CLIENT --> AUTH
        AUTH --> COMMANDS
        INGEST --> CALC
        INGEST --> QUEUE
        CLIENT --> COMMANDS
    end

    subgraph INFRA[Infrastructure]
        CLERK[Clerk]
        METRICS[gRPC metrics service]
        REDIS[(Redis)]
        POSTGRES[(PostgreSQL)]
        PROVIDER[Report model provider]
    end

    AUTH --> CLERK
    INGEST --> METRICS
    COMMANDS --> POSTGRES
    CALC --> COMMANDS
    QUEUE --> REDIS
    QUEUE --> PROVIDER
    QUEUE --> COMMANDS
    MIGRATE --> POSTGRES
```

Fastify route schemas validate the principal request shapes, while shared pre-handlers authenticate every `/ingest` and `/client` request. The middleware upserts the Clerk identity into a local account, and profile-scoped handlers return `404` when the requested profile does not belong to that account. Database access is centralized behind Bun's SQL client and a compatibility adapter that rewrites the repository's positional query syntax for PostgreSQL; multi-row ownership changes and backfills use transactions. Insight generation is asynchronous, with state and errors persisted for polling and recovery.

## Tech stack

| Layer | Technology |
| --- | --- |
| **Language** | TypeScript 6 with strict compiler checks |
| **Runtime** | [Bun](https://bun.sh/) 1.3 |
| **HTTP API** | [Fastify](https://fastify.dev/) 5.9 and `@fastify/websocket` |
| **Authentication** | [Clerk](https://clerk.com/) backend and Fastify integration |
| **Persistence** | PostgreSQL 17 with Bun's built-in `SQL` client |
| **Async jobs** | BullMQ 5.79 with Redis |
| **Metric calculation** | gRPC, Protocol Buffers, and an external `MetricsModel` service |
| **Report generation** | LangChain 1.5 with the configured model provider |
| **Testing** | Bun's built-in test runner with 26 focused tests and TypeScript type checking |
| **Local operations** | Docker Compose for PostgreSQL; optional macOS `launchd` agent |

## Project structure

```text
healthmaxxing/
├── src/
│   ├── app.ts                    # Fastify plugins, routes, and health check
│   ├── main.ts                   # API and report-worker process entry point
│   ├── server.ts                 # Core API-only entry point
│   ├── routes/
│   │   ├── ingest.ts             # Measurement, workout, and backfill writes
│   │   └── client.ts             # Profiles, summaries, trends, and reports
│   ├── middleware/auth.ts        # Clerk authentication and account resolution
│   ├── services/                 # Account-level application services
│   ├── calculations/             # Composition summaries and Forma score
│   ├── bull/                     # Redis queue and report worker lifecycle
│   ├── db/
│   │   ├── client.ts             # Bun SQL connection and query adapter
│   │   ├── commands.ts           # Typed persistence and reporting operations
│   │   └── migrate.ts            # Ordered migration runner
│   └── lib/                      # Backfill and document-conversion clients
├── migrations/                   # PostgreSQL schema history
├── proto/                        # gRPC service contracts
├── scripts/                      # Migration, import, verification, and service tools
├── launchd/                      # macOS service template
├── docker-compose.yml            # Local PostgreSQL 17 service
├── package.json                  # Bun scripts and dependencies
└── tsconfig.json                 # Strict TypeScript configuration
```

## Requirements

- Bun 1.3; the repository is currently validated with Bun 1.3.14.
- Docker and Docker Compose for the included PostgreSQL 17 development service.
- A Clerk application and a valid `CLERK_SECRET_KEY` for authenticated routes.
- A reachable implementation of `proto/metrics_model.proto`; the default address is `localhost:50054`.
- Redis for report jobs; the default connection is `redis://localhost:6379` and Redis is not defined in the included Compose file.
- `OPENAI_API_KEY` for the currently configured structured report model.
- Network access for dependency installation, Clerk verification, and hosted model calls.

No dedicated hardware or UI simulator is required: clients send measurements over HTTP. The Bun API can run on macOS or Linux, while the included `launchd` installer is macOS-only. Production deployments must supply managed PostgreSQL, Redis, authentication, metric-service, and model-provider configuration rather than the local defaults.

## Getting started

1. Clone the repository.

   ```bash
   git clone https://github.com/aneeshpatne/healthmaxxing.git
   cd healthmaxxing
   ```

2. Install dependencies with Bun.

   ```bash
   bun install
   ```

3. Create the local environment file.

   ```bash
   cp .env.example .env
   ```

   Add the services and credentials required by the runtime you intend to use:

   ```dotenv
   DATABASE_URL=postgres://healthmaxxing:healthmaxxing@127.0.0.1:5432/healthmaxxing
   CLERK_SECRET_KEY=replace-with-a-clerk-secret
   METRICS_MODEL_ADDRESS=localhost:50054
   REDIS_URL=redis://localhost:6379
   OPENAI_API_KEY=replace-with-an-openai-key
   PORT=3030
   HOST=0.0.0.0
   ```

   > [!IMPORTANT]
   > The Compose file and `.env.example` contain local development database credentials. Replace them for any shared or production environment, keep provider keys out of version control, and do not distribute the repository with a populated `.env` file.

4. Start PostgreSQL and apply the schema.

   ```bash
   bun run db:up
   bun run db:migrate
   ```

5. Start Redis and the external `MetricsModel` gRPC service using their respective projects. Both must match the addresses configured in `.env` before measurement and report workflows can complete.

6. Run the complete API and report worker.

   ```bash
   bun run start
   ```

   For the core API without the report worker, use:

   ```bash
   bun run server
   ```

   Migrations also run automatically before either server entry point begins listening. Verify the database connection at `http://localhost:3030/health`.

7. Make an authenticated request to `POST /client/register`. The first request creates or refreshes the local account for the Clerk user; create a profile through `POST /client/register/profiles/v2` before ingesting profile-scoped data.

To migrate an existing SQLite database after initializing an empty PostgreSQL database:

```bash
cp mydb.sqlite mydb.sqlite.backup
bun run db:import -- mydb.sqlite
bun run db:verify -- mydb.sqlite
```

The importer refuses a non-empty PostgreSQL target unless `--force` is supplied. Keep the backup until application smoke tests pass.

## Running tests

Run the package test script from a terminal or configure an IDE's Bun test integration to invoke the same script:

```bash
bun run test
```

The direct Bun command is equivalent:

```bash
bun test
```

Run the compiler check separately:

```bash
bun run typecheck
```

The current suite has 26 focused tests across 5 files covering PostgreSQL query translation, trend calculations, profile-context formatting, composition-target calculations, metric validation, and insight-report payload normalization. It does not yet provide end-to-end coverage for Clerk authentication, gRPC calculation, Redis jobs, or the HTTP routes.

## Roadmap

- Extract insight-report generation into its own deployable project while keeping the report API contract stable.
- Add Redis and the external metrics service to a reproducible local orchestration setup.
- Remove the deprecated split registration and `/client/users` routes after downstream clients complete migration.
- Make raw-measurement and derived-snapshot recovery automatic when the gRPC calculation step fails.
- Add integration tests for profile isolation, measurement ingestion, report status transitions, and long polling.
- Publish an OpenAPI reference from the existing Fastify route schemas.

## License

Healthmaxxing is licensed under the [Apache License 2.0](./LICENSE). It permits use, modification, and redistribution under the license's notice and attribution conditions; modified files must be identified, and any applicable patent and NOTICE terms remain in effect.

---

<div align="center">
  Built with Bun, Fastify, PostgreSQL, and a bias toward measurable progress.
</div>
