import { calculateAgeYears } from "../routes/ingest";
import { db } from "./db";
const profileId = "019e8724-ccf0-73cb-9c7d-822478474e90";

const res = db
  .prepare(
    "SELECT body_age_years FROM body_composition_metrics_new WHERE profile_id = ?",
  )
  .get(profileId) as { body_age_years: string } | null;

const res1 = db
  .prepare("SELECT date_of_birth FROM profile_metadata WHERE profile_id = ?")
  .get(profileId) as { date_of_birth: string } | null;

if (res1 === null) {
  throw new Error(`No profile metadata found for profile ${profileId}`);
}

const res3 = db
  .prepare("SELECT * FROM body_measurements WHERE profile_id = ? ")
  .get(profileId);

console.log(calculateAgeYears(res1.date_of_birth));
console.log(res?.body_age_years);
console.log(res3);
