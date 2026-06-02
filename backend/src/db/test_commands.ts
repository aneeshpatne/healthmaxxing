import { Database } from "bun:sqlite";

export const db = new Database("mydb.sqlite");

const profiles = db.prepare("SELECT * FROM profiles").all();

console.log(profiles);
