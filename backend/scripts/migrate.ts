import { sql } from "../src/db/client";
import { migrateDatabase } from "../src/db/migrate";

await migrateDatabase();
console.log("Database migrations are current");

await sql.close();
