import type { ProprietaryBodyCompositionMetrics } from "./proprietaryMetrics";

export type CompositionSummary = {
  body_fat_pct: number;
  lean_mass_pct: number;
  protein_pct: number;
  hydration_pct: number;
  muscle_mass_pct: number;
  composition_score: number;
};

export type DesiredWeightInput = {
  fat_free_mass_kg: number;
  target_body_fat_pct?: number;
};

function round(value: number, digits: number): number {
  return Number(value.toFixed(digits));
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

function rangeScore(value: number, min: number, max: number): number {
  if (value >= min && value <= max) {
    return 100;
  }

  const target = value < min ? min : max;
  const tolerance = Math.max(max - min, target * 0.35, 1);

  return clamp(100 * (1 - Math.abs(value - target) / tolerance), 0, 100);
}

function weightedAverage(
  components: Array<{ score: number; weight: number }>,
): number {
  const totalWeight = components.reduce(
    (sum, component) => sum + component.weight,
    0,
  );

  return Math.round(
    clamp(
      components.reduce(
        (sum, component) => sum + component.score * component.weight,
        0,
      ) / totalWeight,
      0,
      100,
    ),
  );
}

export function calculateCompositionSummary(
  metrics: ProprietaryBodyCompositionMetrics,
): CompositionSummary {
  const weightKg = metrics.fat_mass_kg + metrics.fat_free_mass_kg;

  if (!Number.isFinite(weightKg) || weightKg <= 0) {
    throw new Error("metrics must include positive fat and lean mass");
  }

  const leanMassPct = (metrics.fat_free_mass_kg / weightKg) * 100;
  const muscleMassPct = (metrics.muscle_mass_kg / weightKg) * 100;
  const compositionScore = weightedAverage([
    { score: metrics.body_score, weight: 2 },
    { score: rangeScore(metrics.body_fat_pct, 10, 22), weight: 2 },
    { score: rangeScore(leanMassPct, 75, 90), weight: 1 },
    { score: rangeScore(metrics.water_pct, 50, 65), weight: 1 },
    { score: rangeScore(metrics.protein_pct, 16, 22), weight: 1 },
    { score: rangeScore(muscleMassPct, 40, 60), weight: 2 },
  ]);

  return {
    body_fat_pct: round(metrics.body_fat_pct, 1),
    lean_mass_pct: round(leanMassPct, 1),
    protein_pct: round(metrics.protein_pct, 1),
    hydration_pct: round(metrics.water_pct, 1),
    muscle_mass_pct: round(muscleMassPct, 1),
    composition_score: compositionScore,
  };
}

export function calculateDesiredWeightKg({
  fat_free_mass_kg,
  target_body_fat_pct = 18,
}: DesiredWeightInput): number {
  if (!Number.isFinite(fat_free_mass_kg) || fat_free_mass_kg <= 0) {
    throw new Error("fat_free_mass_kg must be positive");
  }

  if (
    !Number.isFinite(target_body_fat_pct) ||
    target_body_fat_pct <= 0 ||
    target_body_fat_pct >= 100
  ) {
    throw new Error("target_body_fat_pct must be between 0 and 100");
  }

  return round(fat_free_mass_kg / (1 - target_body_fat_pct / 100), 2);
}
