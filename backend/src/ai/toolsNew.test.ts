import { expect, test } from "bun:test";
import {
  insights_schema,
  preprocessProfileAiReportPayload,
} from "./toolsNew";

function remark(text: string) {
  return {
    marker: "complement" as const,
    text,
  };
}

function card(label: string) {
  return {
    heading: `${label} heading`,
    title: `${label} title`,
    comment: `${label} comment`,
    remark: remark(`${label} remark`),
  };
}

function insightCard(label: string) {
  return {
    title: `${label} title`,
    headline: `${label} headline`,
    comment: `${label} comment`,
    remark: remark(`${label} remark`),
  };
}

const payload = insights_schema.parse({
  insights: {
    overview: insightCard("overview"),
    foundation: insightCard("foundation"),
    momentum: insightCard("momentum"),
    progress: {
      ...insightCard("progress"),
      trends: ["bmi", "water_pct"],
    },
    lever: insightCard("lever"),
    physique_archetype: {
      ...insightCard("physique"),
      body_type: "fit",
    },
    effort_score: {
      ...insightCard("effort"),
      score: 72,
    },
  },
  performance: {
    ffmi_gauge: card("ffmi"),
    fmi_vs_ffmi: card("fmi vs ffmi"),
    body_composition_flow: card("composition flow"),
    composition_trends: card("composition trends"),
    target_vs_current_weight: card("target vs current"),
    excess_fat_gauge: card("excess fat"),
  },
  fat: {
    fat_ratio: card("fat ratio"),
    fat_ratio_trend: card("fat ratio trend"),
    visceral_vs_subcutaneous: card("visceral vs subcutaneous"),
    visceral_trend: card("visceral trend"),
    subcutaneous_fat_mass_trend: card("subcutaneous trend"),
    fat_mass_trend: card("fat mass trend"),
  },
  muscle: {
    muscle_mass: card("muscle mass"),
    bone_mass_trend: card("bone mass trend"),
    muscle_ratio_trend: card("muscle ratio trend"),
    skeletal_muscle_mass_trend: card("skeletal muscle trend"),
  },
});

const trend = [{ createdAt: "2026-06-01", value: 1.25 }];
const sources = {
  performanceReport: {
    ffmi: 21.4,
    ffmiVsFmi: { ffmi: 21.4, fmi: 5.7 },
    bodyComposition: { leanMassKg: 54, fatMassKg: 18 },
    compositionTrends: {
      leanMass30Days: trend,
      fatMass30Days: [{ createdAt: "2026-06-01", value: -0.4 }],
    },
    weightPair: {
      target: { leanMassKg: 54, fatMassKg: 12 },
      current: { leanMassKg: 54, fatMassKg: 18 },
      initial: { leanMassKg: 52, fatMassKg: 20 },
    },
    excessFatGauge: { totalFatKg: 18, targetFatKg: 12, excessFatKg: 6 },
    bodyMeasurements: [],
    lastBodyRatios: {
      waistHeight: null,
      shoulderWaist: null,
      chestWaist: null,
      bicepForearm: null,
      thighCalf: null,
      neckCalf: null,
    },
    comments: null,
  },
  fatReport: {
    id: "fat-report-id",
    profileId: "profile-id",
    bodyCompositionMetricsId: "metrics-id",
    createdAt: "2026-06-01",
    metrics: {
      fatPercent: 24.5,
      visceralSubcutaneous30dDelta: {
        visceralFatDeltaKg: -0.2,
        subcutaneousFatDeltaKg: -0.5,
      },
      fatMassKg: 18,
      visceralFatMassKg: 5,
      visceralFatPercent: 6.8,
      subcutaneousFatMassKg: 13,
      subcutaneousFatRatio: 0.72,
    },
    last30Days: {
      fatPercent: [{ createdAt: "2026-06-01", value: 24.5 }],
      fatMassKg: trend,
      visceralFatMassKg: [{ createdAt: "2026-06-01", value: -0.2 }],
      subcutaneousFatMassKg: [{ createdAt: "2026-06-01", value: -0.5 }],
      visceralFatPercent: [{ createdAt: "2026-06-01", value: -0.1 }],
      subcutaneousFatPercent: [{ createdAt: "2026-06-01", value: -0.3 }],
    },
    comments: {},
  },
  muscleReport: {
    id: "muscle-report-id",
    profileId: "profile-id",
    bodyCompositionMetricsId: "metrics-id",
    createdAt: "2026-06-01",
    metrics: {
      totalMuscleKg: 42,
      boneMassKg: 12,
      muscleRatio: 56,
      skeletalMuscleMassKg: 31,
      skeletalMuscleRatio: 41,
    },
    last30Days: {
      boneMassKg: [{ createdAt: "2026-06-01", value: 0.1 }],
      muscleMassKg: [{ createdAt: "2026-06-01", value: 42 }],
      muscleRatio: [{ createdAt: "2026-06-01", value: 0.4 }],
      skeletalMuscleMassKg: [{ createdAt: "2026-06-01", value: 0.2 }],
      skeletalMuscleRatio: [{ createdAt: "2026-06-01", value: 0.3 }],
    },
    comments: {},
  },
  progressTrends: {
    body_fat_pct: [{ createdAt: "2026-06-01", value: 24.5 }],
    fat_mass_kg: [{ createdAt: "2026-06-01", value: 18 }],
    muscle_mass_kg: [{ createdAt: "2026-06-01", value: 42 }],
  },
};

test("preprocessProfileAiReportPayload forces progress trends only", () => {
  const preprocessed = preprocessProfileAiReportPayload(payload, sources);

  expect(preprocessed.insights.progress.trends).toEqual([
    "body_fat_pct",
    "fat_mass_kg",
    "muscle_mass_kg",
  ]);
  expect(preprocessed.insights.progress.preprocess).toEqual({
    trends: sources.progressTrends,
  });
  expect("value" in preprocessed.insights.progress.preprocess).toBe(false);
  expect(preprocessed.insights.progress.comment).toBe("progress comment");
});

test("preprocessProfileAiReportPayload marks performance source types", () => {
  const preprocessed = preprocessProfileAiReportPayload(payload, sources);

  expect(preprocessed.performance.ffmi_gauge.preprocess).toEqual({
    value: 21.4,
  });
  expect("trends" in preprocessed.performance.ffmi_gauge.preprocess).toBe(false);
  expect(preprocessed.performance.composition_trends.preprocess).toEqual({
    trends: sources.performanceReport.compositionTrends,
  });
  expect("value" in preprocessed.performance.composition_trends.preprocess).toBe(
    false,
  );
  expect(preprocessed.performance.excess_fat_gauge.preprocess).toEqual({
    value: sources.performanceReport.excessFatGauge,
  });
});

test("preprocessProfileAiReportPayload marks fat and muscle with values and trends", () => {
  const preprocessed = preprocessProfileAiReportPayload(payload, sources);

  expect(preprocessed.fat.fat_ratio.preprocess).toEqual({
    value: 24.5,
    trends: { fatPercent: sources.fatReport.last30Days.fatPercent },
  });
  expect(preprocessed.fat.fat_ratio_trend.preprocess).toEqual({
    value: 24.5,
    trends: { fatPercent: sources.fatReport.last30Days.fatPercent },
  });
  expect(preprocessed.fat.visceral_vs_subcutaneous.preprocess).toEqual({
    value: sources.fatReport.metrics.visceralSubcutaneous30dDelta,
    trends: {
      visceralFatMassKg: sources.fatReport.last30Days.visceralFatMassKg,
      subcutaneousFatMassKg:
        sources.fatReport.last30Days.subcutaneousFatMassKg,
    },
  });
  expect(preprocessed.fat.fat_mass_trend.preprocess).toEqual({
    value: 18,
    trends: { fatMassKg: trend },
  });
  expect(preprocessed.muscle.muscle_mass.preprocess).toEqual({
    value: 42,
    trends: { muscleMassKg: sources.muscleReport.last30Days.muscleMassKg },
  });
  expect(preprocessed.muscle.muscle_ratio_trend.preprocess).toEqual({
    value: 56,
    trends: { muscleRatio: sources.muscleReport.last30Days.muscleRatio },
  });
  expect(preprocessed.muscle.skeletal_muscle_mass_trend.preprocess).toEqual({
    value: 31,
    trends: {
      skeletalMuscleMassKg:
        sources.muscleReport.last30Days.skeletalMuscleMassKg,
      skeletalMuscleRatio:
        sources.muscleReport.last30Days.skeletalMuscleRatio,
    },
  });
  expect(preprocessed.muscle.skeletal_muscle_mass_trend.title).toBe(
    "skeletal muscle trend title",
  );
});

test("preprocessProfileAiReportPayload does not emit source keys", () => {
  const preprocessed = preprocessProfileAiReportPayload(payload, sources);
  const serialized = JSON.stringify(preprocessed);

  expect(serialized.includes("valueKey")).toBe(false);
  expect(serialized.includes("trendKeys")).toBe(false);
});
