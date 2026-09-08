import { SQL } from "bun";

const databaseUrl = process.env.DATABASE_URL;

if (!databaseUrl) {
  throw new Error("DATABASE_URL is required");
}

export const sql = new SQL(databaseUrl, {
  max: Number(process.env.DATABASE_POOL_SIZE ?? 10),
  idleTimeout: 30,
  connectionTimeout: 10,
});

function rewriteTwoArgumentRound(source: string): string {
  let output = "";
  let cursor = 0;
  while (cursor < source.length) {
    const start = source.toUpperCase().indexOf("ROUND(", cursor);
    if (start === -1) return output + source.slice(cursor);
    output += source.slice(cursor, start);
    let depth = 1;
    let comma = -1;
    let end = start + 6;
    for (; end < source.length && depth > 0; end++) {
      const character = source[end];
      if (character === "(") depth++;
      else if (character === ")") depth--;
      else if (character === "," && depth === 1) comma = end;
    }
    if (depth !== 0 || comma === -1) {
      output += source.slice(start, end);
      cursor = end;
      continue;
    }
    const expression = source.slice(start + 6, comma);
    const precision = source.slice(comma + 1, end - 1);
    output += `ROUND((${rewriteTwoArgumentRound(expression)})::numeric, ${precision})::double precision`;
    cursor = end;
  }
  return output;
}

const convertedQueries = new Map<string, string>();
const MAX_CONVERTED_QUERIES = 256;

export function postgresQuery(source: string): string {
  const cached = convertedQueries.get(source);
  if (cached !== undefined) return cached;
  let parameter = 0;
  const converted = rewriteTwoArgumentRound(source)
    .replace(/\?/g, () => `$${++parameter}`)
    .replace(/\bAS\s+([a-z_]*[A-Z][A-Za-z0-9_]*)\b/g, 'AS "$1"')
    .replace(/datetime\('now',\s*'-1 year'\)/gi, "CURRENT_TIMESTAMP - INTERVAL '1 year'")
    .replace(/datetime\('now',\s*'-30 days'\)/gi, "CURRENT_TIMESTAMP - INTERVAL '30 days'")
    .replace(/datetime\('now',\s*'-7 days'\)/gi, "CURRENT_TIMESTAMP - INTERVAL '7 days'")
    .replace(/datetime\(([^,]+),\s*'-30 days'\)/gi, "$1 - INTERVAL '30 days'")
    .replace(/datetime\('now',\s*(\$\d+)\)/gi, "CURRENT_TIMESTAMP + $1::interval")
    .replace(/\bMAX\(([^,()]+),\s*0\)/gi, "GREATEST($1, 0)")
    .replace(/\bis_trendable\s*=\s*1\b/gi, "is_trendable = true");
  if (convertedQueries.size >= MAX_CONVERTED_QUERIES) {
    convertedQueries.delete(convertedQueries.keys().next().value!);
  }
  convertedQueries.set(source, converted);
  return converted;
}

type QueryRows = Record<string, unknown>[];

export interface DatabaseClient {
  prepare(source: string): PreparedQuery;
  run(source: string): Promise<void>;
  transaction<T>(callback: (tx: DatabaseClient) => Promise<T>): Promise<T>;
}

class PreparedQuery {
  constructor(private readonly source: string) {}

  async all(...parameters: unknown[]): Promise<QueryRows> {
    return (await sql.unsafe(postgresQuery(this.source), parameters)) as QueryRows;
  }

  async get(...parameters: unknown[]): Promise<Record<string, unknown> | null> {
    const rows = await this.all(...parameters);
    return rows[0] ?? null;
  }

  async run(...parameters: unknown[]): Promise<void> {
    await sql.unsafe(postgresQuery(this.source), parameters);
  }
}

export const db: DatabaseClient = {
  prepare(source: string) {
    return new PreparedQuery(source);
  },
  async run(source: string) {
    await sql.unsafe(postgresQuery(source));
  },
  async transaction<T>(callback: (tx: typeof db) => Promise<T>): Promise<T> {
    return sql.begin(async (transaction) => {
      const txDb = {
        prepare(source: string) {
          const converted = postgresQuery(source);
          return {
            all: async (...parameters: unknown[]) =>
              (await transaction.unsafe(converted, parameters)) as QueryRows,
            get: async (...parameters: unknown[]) => {
              const rows = (await transaction.unsafe(converted, parameters)) as QueryRows;
              return rows[0] ?? null;
            },
            run: async (...parameters: unknown[]) => {
              await transaction.unsafe(converted, parameters);
            },
          };
        },
        async run(source: string) {
          await transaction.unsafe(postgresQuery(source));
        },
        transaction: db.transaction,
      } as DatabaseClient;
      return callback(txDb);
    });
  },
};

export async function closeDatabase() {
  await sql.close({ timeout: 5 });
}

export async function checkDatabase() {
  await sql`SELECT 1`;
}
