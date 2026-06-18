import { db } from "./db";
import {
  normalizeWorkout,
  type AppleHealthWorkoutName,
  type Workout,
  type WorkoutData,
} from "./commands";

const workoutName: AppleHealthWorkoutName = "Traditional Strength Training";
const data = db
  .prepare("SELECT raw_payload FROM workouts WHERE name= ?")
  .all(workoutName) as { raw_payload: string }[];

const workouts: WorkoutData[] = data.map(
  (d) => JSON.parse(d.raw_payload) as WorkoutData,
);
const normalizedWorkouts: Workout[] = workouts.map(normalizeWorkout);

console.log(normalizedWorkouts.map((workout) => workout.type));
