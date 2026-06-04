import { db } from "./db";
const profileId = "019e8724-ccf0-73cb-9c7d-822478474e90";

const res = db
  .prepare(
    "SELECT created_at, body_fat_pct FROM body_composition_metrics_new WHERE profile_id = ? AND created_at >= datetime('now', '-7 days')",
  )
  .all(profileId);

console.log(res);
