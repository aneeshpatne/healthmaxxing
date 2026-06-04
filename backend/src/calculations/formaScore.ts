import type { ProprietaryBodyCompositionMetrics } from "./proprietaryMetrics";

export type FormaScoreRemark =
  | "Excellent"
  | "Good"
  | "Moderate"
  | "Poor"
  | "Critical";

export type FormaScore = {
  score: number;
  remark: FormaScoreRemark;
};

export type FormaScoreMetrics = ProprietaryBodyCompositionMetrics & {
  desired_weight_kg: number;
};

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

function targetScore(value: number, target: number, tolerance: number): number {
  return clamp(100 * (1 - Math.abs(value - target) / tolerance), 0, 100);
}

function ratioScore(numerator: number, denominator: number, min: number, max: number): number {
  if (denominator <= 0) {
    return 0;
  }

  return rangeScore((numerator / denominator) * 100, min, max);
}

function remarkForScore(score: number): FormaScoreRemark {
  if (score >= 85) return "Excellent";
  if (score >= 70) return "Good";
  if (score >= 50) return "Moderate";
  if (score >= 30) return "Poor";
  return "Critical";
}

export function calculateFormaScore(
  metrics: FormaScoreMetrics,
): FormaScore {
  const weightKg = metrics.fat_mass_kg + metrics.fat_free_mass_kg;
  const weightedComponents = [
    { score: metrics.body_score, weight: 2 },
    { score: rangeScore(metrics.bmi, 18.5, 24.9), weight: 1 },
    { score: rangeScore(metrics.body_fat_pct, 10, 22), weight: 2 },
    { score: rangeScore(metrics.water_pct, 50, 65), weight: 1 },
    { score: rangeScore(metrics.protein_pct, 16, 22), weight: 1 },
    { score: rangeScore(metrics.muscle_rate_pct, 65, 85), weight: 2 },
    { score: rangeScore(metrics.visceral_fat, 1, 9), weight: 2 },
    { score: rangeScore(metrics.subcutaneous_fat_pct, 6, 18), weight: 1 },
    { score: ratioScore(metrics.fat_free_mass_kg, weightKg, 75, 90), weight: 1 },
    { score: ratioScore(metrics.predicted_lean_mass_kg, weightKg, 75, 90), weight: 1 },
    { score: ratioScore(metrics.muscle_mass_kg, weightKg, 40, 60), weight: 1 },
    { score: ratioScore(metrics.skeletal_muscle_kg, weightKg, 40, 60), weight: 1 },
    { score: ratioScore(metrics.protein_mass_kg, weightKg, 14, 20), weight: 1 },
    { score: ratioScore(metrics.subcutaneous_fat_mass_kg, weightKg, 6, 18), weight: 1 },
    { score: targetScore(metrics.fat_mass_kg, weightKg * 0.16, weightKg * 0.16), weight: 1 },
    { score: targetScore(metrics.desired_weight_kg, weightKg, weightKg * 0.25), weight: 1 },
    { score: targetScore(metrics.ideal_weight_kg, weightKg, weightKg * 0.25), weight: 1 },
    { score: rangeScore(metrics.bmr_kcal, 1300, 2300), weight: 1 },
    { score: rangeScore(metrics.body_age_years, 18, 45), weight: 1 },
  ];

  const totalWeight = weightedComponents.reduce(
    (sum, component) => sum + component.weight,
    0,
  );
  const rawScore =
    weightedComponents.reduce(
      (sum, component) => sum + component.score * component.weight,
      0,
    ) / totalWeight;
  const score = Math.round(clamp(rawScore, 0, 100));

  return {
    score,
    remark: remarkForScore(score),
  };
}
