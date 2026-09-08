import path from "node:path";
import { fileURLToPath } from "node:url";
import * as grpc from "@grpc/grpc-js";
import * as protoLoader from "@grpc/proto-loader";

export type Sex = "male" | "female" | string;
export type PeopleType = "standard" | "athlete";

export type ProprietaryMetricsInput = {
  weight_kg: number;
  impedance_ohms: number;
  height_cm: number;
  age_years: number;
  sex: Sex;
  people_type?: PeopleType | string | null;
};

export type ProprietaryBodyCompositionMetrics = {
  bmi: number;
  body_fat_pct: number;
  fat_mass_kg: number;
  fat_free_mass_kg: number;
  body_score: number;
  body_age_years: number;
  water_pct: number;
  muscle_mass_kg: number;
  muscle_rate_pct: number;
  bmr_kcal: number;
  visceral_fat: number;
  ideal_weight_kg: number;
  protein_mass_kg: number;
  protein_pct: number;
  skeletal_muscle_kg: number;
  subcutaneous_fat_pct: number;
  subcutaneous_fat_mass_kg: number;
  predicted_lean_mass_kg: number;
};

type MetricsModelSex = "SEX_UNSPECIFIED" | "SEX_FEMALE" | "SEX_MALE";

type CalculateRequest = {
  age: number;
  height_cm: number;
  weight_kg: number;
  sex: MetricsModelSex;
  impedance: number;
  people_type: string;
};

type CalculateResponse = {
  metrics?: Record<string, number>;
};

type MetricsModelClient = grpc.Client & {
  Calculate(
    request: CalculateRequest,
    callback: grpc.requestCallback<CalculateResponse>,
  ): grpc.ClientUnaryCall;
};

type MetricsModelProto = {
  metrics_model: {
    MetricsModel: grpc.ServiceClientConstructor;
  };
};

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROTO_PATH = path.resolve(__dirname, "../../proto/metrics_model.proto");
const METRICS_MODEL_ADDRESS =
  process.env.METRICS_MODEL_ADDRESS ?? "localhost:50054";

const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  defaults: true,
  enums: String,
  keepCase: true,
  longs: String,
  oneofs: true,
});

const metricsModelProto = grpc.loadPackageDefinition(
  packageDefinition,
) as unknown as MetricsModelProto;

const REQUIRED_METRIC_KEYS = [
  "bmi",
  "body_fat_pct",
  "fat_mass_kg",
  "fat_free_mass_kg",
  "body_score",
  "body_age_years",
  "water_pct",
  "muscle_mass_kg",
  "muscle_rate_pct",
  "bmr_kcal",
  "visceral_fat",
  "ideal_weight_kg",
  "protein_mass_kg",
  "protein_pct",
  "skeletal_muscle_kg",
  "subcutaneous_fat_pct",
  "subcutaneous_fat_mass_kg",
  "predicted_lean_mass_kg",
] as const satisfies readonly (keyof ProprietaryBodyCompositionMetrics)[];

function round(value: number, digits: number): number {
  return Number(value.toFixed(digits));
}

function normalizeMetricsModelSex(sex: Sex): MetricsModelSex {
  const normalized = String(sex).toLowerCase();

  if (normalized === "female" || normalized === "sex_female") {
    return "SEX_FEMALE";
  }

  if (normalized === "male" || normalized === "sex_male") {
    return "SEX_MALE";
  }

  throw new Error("sex must be male or female");
}

function validatePositive(value: number, name: string): void {
  if (!Number.isFinite(value) || value <= 0) {
    throw new Error(`${name} must be positive`);
  }
}

function validateRange(
  value: number,
  name: string,
  minimum: number,
  maximum: number,
): void {
  if (!Number.isFinite(value) || value < minimum || value > maximum) {
    throw new Error(`${name} must be between ${minimum} and ${maximum}`);
  }
}

function createMetricsModelClient(
  address = METRICS_MODEL_ADDRESS,
): MetricsModelClient {
  return new metricsModelProto.metrics_model.MetricsModel(
    address,
    grpc.credentials.createInsecure(),
  ) as unknown as MetricsModelClient;
}

export function coerceMetrics(
  metrics: Record<string, number> | undefined,
  weightKg: number,
): ProprietaryBodyCompositionMetrics {
  if (!metrics) {
    throw new Error("metrics model response did not include metrics");
  }

  const rawMetric = (key: string): number | undefined => {
    const value = metrics[key];
    return typeof value === "number" && Number.isFinite(value)
      ? value
      : undefined;
  };
  const proteinRate = rawMetric("proteinRate");

  const aliases = {
    bmi: rawMetric("bmi"),
    body_fat_pct: rawMetric("body_fat_pct") ?? rawMetric("bodyFatRate"),
    fat_mass_kg: rawMetric("fat_mass_kg") ?? rawMetric("bodyFatKg"),
    fat_free_mass_kg: rawMetric("fat_free_mass_kg") ?? rawMetric("fatFreeMass"),
    body_score: rawMetric("body_score") ?? rawMetric("bodyScore"),
    body_age_years: rawMetric("body_age_years") ?? rawMetric("bodyAge"),
    water_pct: rawMetric("water_pct") ?? rawMetric("waterRate"),
    muscle_mass_kg: rawMetric("muscle_mass_kg") ?? rawMetric("muscleKg"),
    muscle_rate_pct: rawMetric("muscle_rate_pct") ?? rawMetric("muscleRate"),
    bmr_kcal: rawMetric("bmr_kcal") ?? rawMetric("bmr"),
    visceral_fat: rawMetric("visceral_fat") ?? rawMetric("vfal"),
    ideal_weight_kg: rawMetric("ideal_weight_kg") ?? rawMetric("idealWeight"),
    protein_mass_kg:
      rawMetric("protein_mass_kg") ??
      (proteinRate === undefined ? undefined : (proteinRate * weightKg) / 100),
    protein_pct: rawMetric("protein_pct") ?? proteinRate,
    skeletal_muscle_kg:
      rawMetric("skeletal_muscle_kg") ?? rawMetric("skeletalMuscleKg"),
    subcutaneous_fat_pct:
      rawMetric("subcutaneous_fat_pct") ?? rawMetric("subcutRate"),
    subcutaneous_fat_mass_kg:
      rawMetric("subcutaneous_fat_mass_kg") ?? rawMetric("subcutKg"),
    predicted_lean_mass_kg:
      rawMetric("predicted_lean_mass_kg") ??
      rawMetric("predictedLeanMassKg") ??
      rawMetric("fatFreeMass"),
  } satisfies Record<keyof ProprietaryBodyCompositionMetrics, number | undefined>;

  const missingKeys = REQUIRED_METRIC_KEYS.filter((key) => {
    const value = aliases[key];
    return typeof value !== "number" || !Number.isFinite(value);
  });

  if (missingKeys.length > 0) {
    throw new Error(
      `metrics model response missing required metrics: ${missingKeys.join(", ")}`,
    );
  }

  const metric = (key: keyof ProprietaryBodyCompositionMetrics): number => {
    const value = aliases[key];
    if (typeof value !== "number" || !Number.isFinite(value)) {
      throw new Error(`metrics model response missing required metric: ${key}`);
    }

    return value;
  };

  const result = {
    bmi: metric("bmi"),
    body_fat_pct: metric("body_fat_pct"),
    fat_mass_kg: metric("fat_mass_kg"),
    fat_free_mass_kg: metric("fat_free_mass_kg"),
    body_score: Math.round(metric("body_score")),
    body_age_years: Math.round(metric("body_age_years")),
    water_pct: metric("water_pct"),
    muscle_mass_kg: metric("muscle_mass_kg"),
    muscle_rate_pct: metric("muscle_rate_pct"),
    bmr_kcal: Math.round(metric("bmr_kcal")),
    visceral_fat: Math.round(metric("visceral_fat")),
    ideal_weight_kg: metric("ideal_weight_kg"),
    protein_mass_kg: metric("protein_mass_kg"),
    protein_pct: metric("protein_pct"),
    skeletal_muscle_kg: metric("skeletal_muscle_kg"),
    subcutaneous_fat_pct: metric("subcutaneous_fat_pct"),
    subcutaneous_fat_mass_kg: metric("subcutaneous_fat_mass_kg"),
    predicted_lean_mass_kg: metric("predicted_lean_mass_kg"),
  };

  const percentageKeys = [
    "body_fat_pct",
    "water_pct",
    "muscle_rate_pct",
    "protein_pct",
    "subcutaneous_fat_pct",
  ] as const;
  for (const key of percentageKeys) {
    if (result[key] < 0 || result[key] > 100) {
      throw new Error(`metrics model returned out-of-range percentage: ${key}`);
    }
  }

  const massKeys = [
    "fat_mass_kg",
    "fat_free_mass_kg",
    "muscle_mass_kg",
    "protein_mass_kg",
    "skeletal_muscle_kg",
    "subcutaneous_fat_mass_kg",
    "predicted_lean_mass_kg",
  ] as const;
  for (const key of massKeys) {
    if (result[key] < 0 || result[key] > weightKg * 1.1) {
      throw new Error(`metrics model returned out-of-range mass: ${key}`);
    }
  }

  const massTotal = result.fat_mass_kg + result.fat_free_mass_kg;
  if (Math.abs(massTotal - weightKg) > Math.max(0.5, weightKg * 0.02)) {
    throw new Error("metrics model fat and fat-free mass do not match weight");
  }
  if (result.subcutaneous_fat_mass_kg > result.fat_mass_kg + 0.1) {
    throw new Error("metrics model subcutaneous fat exceeds total fat mass");
  }
  if (result.muscle_mass_kg > result.fat_free_mass_kg + 0.1) {
    throw new Error("metrics model muscle mass exceeds fat-free mass");
  }
  if (result.body_score < 0 || result.body_score > 100) {
    throw new Error("metrics model body score must be between 0 and 100");
  }

  return result;
}

export function calculateFmi(fat_mass_kg: number, height_cm: number): number {
  validatePositive(fat_mass_kg, "fat_mass_kg");
  validatePositive(height_cm, "height_cm");

  const heightM = height_cm / 100;
  return round(fat_mass_kg / (heightM * heightM), 2);
}

export function calculateFfmi(
  fat_free_mass_kg: number,
  height_cm: number,
): number {
  validatePositive(fat_free_mass_kg, "fat_free_mass_kg");
  validatePositive(height_cm, "height_cm");

  const heightM = height_cm / 100;
  return round(fat_free_mass_kg / (heightM * heightM), 2);
}

export async function calculateProprietaryMetrics({
  weight_kg,
  impedance_ohms,
  height_cm,
  age_years,
  sex,
  people_type,
}: ProprietaryMetricsInput) {
  validateRange(weight_kg, "weight_kg", 10, 500);
  validateRange(impedance_ohms, "impedance_ohms", 50, 2000);
  validateRange(height_cm, "height_cm", 50, 250);
  validateRange(age_years, "age_years", 5, 120);
  const normalizedPeopleType = String(people_type ?? "standard").toLowerCase();
  if (normalizedPeopleType !== "standard" && normalizedPeopleType !== "athlete") {
    throw new Error("people_type must be standard or athlete");
  }

  const client = createMetricsModelClient();

  try {
    const response = await new Promise<CalculateResponse>((resolve, reject) => {
      client.Calculate(
        {
          age: age_years,
          height_cm,
          weight_kg,
          sex: normalizeMetricsModelSex(sex),
          impedance: impedance_ohms,
          people_type: normalizedPeopleType,
        },
        (error, response) => {
          if (error) {
            reject(error);
            return;
          }

          resolve(response ?? {});
        },
      );
    });

    return coerceMetrics(response.metrics, weight_kg);
  } finally {
    client.close();
  }
}
