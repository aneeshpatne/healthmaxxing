# healthmaxxing

The service uses PostgreSQL through Bun's built-in `SQL` client. PostgreSQL runs
locally in Docker under Colima; the Bun application runs on the host.

To install dependencies:

```bash
bun install
```

## Local database

```bash
cp .env.example .env
colima start
bun run db:up
bun run db:migrate
```

To migrate the existing SQLite data after creating an empty PostgreSQL database:

```bash
cp mydb.sqlite mydb.sqlite.backup
bun run db:import -- mydb.sqlite
bun run db:verify -- mydb.sqlite
```

The importer refuses a non-empty PostgreSQL target unless `--force` is passed.
Keep the SQLite backup until application smoke tests pass.

## Run

```bash
bun run start
```

`GET /health` returns HTTP 200 when PostgreSQL is reachable and HTTP 503 when it
is unavailable. Schema migrations run automatically before the server listens.

Useful commands:

```bash
bun run db:down
bun run typecheck
bun test
```

This project was created using `bun init` in bun v1.3.6. [Bun](https://bun.com) is a fast all-in-one JavaScript runtime.
