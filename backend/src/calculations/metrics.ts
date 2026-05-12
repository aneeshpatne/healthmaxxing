export type Sex = "male" | "female";

export type HealthMetrics = {
  weight_kg: number;
  impedance_ohms: number;
  body_fat_pct: number;
  muscle_mass_kg: number;
  water_pct: number;
  protein_pct: number;
  fat_free_mass_kg: number;
  fat_mass_kg: number;
};

function round(value: number, digits: number): number {
  return Number(value.toFixed(digits));
}

export function calculateHealthMetrics(
  weight_kg: number,
  impedance_ohms: number,
  height_cm: number,
  age_years: number,
  sex: Sex = "male",
): HealthMetrics {
  return calculateHealthMetricsV1(
    weight_kg,
    impedance_ohms,
    height_cm,
    age_years,
    sex,
  );
}

export function calculateHealthMetricsV1(
  weight_kg: number,
  impedance_ohms: number,
  height_cm: number,
  age_years: number,
  sex: Sex,
): HealthMetrics {
  const index = Math.pow(height_cm, 2) / impedance_ohms;

  const a = 0.45;
  const b = 0.28;
  const c = 0.12;
  const d = sex.toLowerCase() === "male" ? 7.0 : 4.5;

  const fatFreeMass = a * index + b * weight_kg - c * age_years + d;
  const fatMass = weight_kg - fatFreeMass;
  const bodyFatPct = (fatMass / weight_kg) * 100;
  const muscleMass = fatFreeMass - 4.9;
  const waterPct = ((fatFreeMass * 0.658) / weight_kg) * 100;
  const proteinPct = ((fatFreeMass * 0.202) / weight_kg) * 100;

  return {
    weight_kg: round(weight_kg, 2),
    impedance_ohms: round(impedance_ohms, 2),
    body_fat_pct: round(bodyFatPct, 1),
    muscle_mass_kg: round(muscleMass, 1),
    water_pct: round(waterPct, 1),
    protein_pct: round(proteinPct, 1),
    fat_free_mass_kg: round(fatFreeMass, 2),
    fat_mass_kg: round(fatMass, 2),
  };
}

export function calculateHealthMetricsV2(
  weight_kg: number,
  impedance_ohms: number,
  height_cm: number,
  age_years: number,
  sex: Sex,
): HealthMetrics {
  if (weight_kg <= 0) throw new Error("weight_kg must be positive");
  if (impedance_ohms <= 0) throw new Error("impedance_ohms must be positive");
  if (height_cm <= 0) throw new Error("height_cm must be positive");
  if (age_years <= 0) throw new Error("age_years must be positive");

  const isMale = sex.toLowerCase() === "male";
  const index = Math.pow(height_cm, 2) / impedance_ohms;

  let fatFreeMass =
    0.44 * index + 0.29 * weight_kg - 0.1 * age_years + (isMale ? 6.65 : 4.25);

  fatFreeMass = clamp(fatFreeMass, weight_kg * 0.5, weight_kg * 0.9);

  const fatMass = weight_kg - fatFreeMass;
  const bodyFatPct = (fatMass / weight_kg) * 100;
  const muscleMass = fatFreeMass * (isMale ? 0.53 : 0.49);
  const waterPct = ((fatFreeMass * 0.72) / weight_kg) * 100;
  const proteinPct = ((fatFreeMass * 0.2) / weight_kg) * 100;

  return {
    weight_kg: round(weight_kg, 2),
    impedance_ohms: round(impedance_ohms, 2),
    body_fat_pct: round(bodyFatPct, 1),
    muscle_mass_kg: round(muscleMass, 1),
    water_pct: round(waterPct, 1),
    protein_pct: round(proteinPct, 1),
    fat_free_mass_kg: round(fatFreeMass, 2),
    fat_mass_kg: round(fatMass, 2),
  };
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}
console.log(calculateHealthMetricsV2(77, 385.38, 172, 25, "male"));
