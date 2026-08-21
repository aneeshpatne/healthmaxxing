import { expect, test } from "bun:test";
import {
  formatBoneMassTrendForAgent,
  buildProfileAiTrendSources,
  insights_schema,
  normalizeProgressTrend,
  preprocessProfileAiReportPayload,
} from "./toolsNew";

function remark(
  text: string,
  factorColor: "red" | "orange" | "yellow" | "green" = "green",
) {
  return {
    marker: "complement" as const,
    factor_color: factorColor,
    text,
  };
}

function card(
  label: string,
  factorColor: "red" | "orange" | "yellow" | "green" = "green",
) {
  return {
    heading: `${label} heading`,
    title: `${label} title`,
    comment: `${label} comment`,
    remark: remark(`${label} remark`, factorColor),
  };
}

function gaugeCard(
  label: string,
  factorColor: "red" | "orange" | "yellow" | "green" = "green",
) {
  return {
    ...card(label, factorColor),
    factor_color: factorColor,
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
    factor: {
      factor: "skeletal_muscle_kg",
      factor_color: "yellow",
      comment: "Skeletal muscle has the clearest potential.",
      remark: remark(
        "Build steadily from your current muscle base.",
        "yellow",
      ),
    },
    key_trend: {
      ...insightCard("key trend"),
      metric: "skeletal_muscle_kg",
    },
    progress: {
      ...insightCard("progress"),
      trends: ["body_fat_pct", "fat_mass_kg"],
    },
  },
  performance: {
    ffmi_gauge: gaugeCard("ffmi"),
    fmi_vs_ffmi: card("fmi vs ffmi"),
    body_composition_flow: card("composition flow"),
    composition_trends: card("composition trends"),
    target_vs_current_weight: card("target vs current"),
    excess_fat_gauge: card("excess fat"),
  },
  fat: {
    fat_ratio: gaugeCard("fat ratio", "yellow"),
    fat_ratio_trend: card("fat ratio trend"),
    visceral_vs_subcutaneous: card("fat distribution context"),
    visceral_trend: card("visceral trend"),
    subcutaneous_fat_mass_trend: card("subcutaneous trend"),
    fat_mass_trend: card("fat mass trend"),
  },
  muscle: {
    skeletal_muscle_gauge: gaugeCard("skeletal muscle gauge"),
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
      target: {
        weightKg: 79.39,
        leanMassKg: 65.12,
        fatMassKg: 14.27,
        bodyFatPct: 18,
        ffmi: 22,
        muscularityGoal: "muscular" as const,
      },
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
      visceralFatIndex: 8,
      fatDistribution30dDelta: {
        visceralFatIndexDelta: -0.2,
        subcutaneousFatDeltaKg: -0.5,
      },
      fatMassKg: 18,
      subcutaneousFatMassKg: 13,
      subcutaneousFatRatio: 0.72,
    },
    last30Days: {
      fatPercent: [{ createdAt: "2026-06-01", value: 24.5 }],
      fatMassKg: trend,
      visceralFatIndex: [{ createdAt: "2026-06-01", value: 8 }],
      subcutaneousFatMassKg: [{ createdAt: "2026-06-01", value: -0.5 }],
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
      leanNonMuscleMassKg: 12,
      muscleRatio: 56,
      skeletalMuscleMassKg: 31,
      skeletalMuscleRatio: 41,
    },
    last30Days: {
      leanNonMuscleMassKg: [{ createdAt: "2026-06-01", value: 0.1 }],
      muscleMassKg: [{ createdAt: "2026-06-01", value: 42 }],
      muscleRatio: [{ createdAt: "2026-06-01", value: 0.4 }],
      skeletalMuscleMassKg: [{ createdAt: "2026-06-01", value: 0.2 }],
      skeletalMuscleRatio: [{ createdAt: "2026-06-01", value: 0.3 }],
    },
    comments: {},
  },
  trendSources: {
    fullHistory: {
      body_fat_pct: [{ createdAt: "2026-01-01", value: 28 }],
      fat_mass_kg: [{ createdAt: "2026-01-01", value: 20 }],
      muscle_mass_kg: [{ createdAt: "2026-01-01", value: 40 }],
      skeletal_muscle_kg: [
        { createdAt: "2026-01-01", value: 29 },
        { createdAt: "2026-06-01", value: 31 },
      ],
      visceral_fat: [{ createdAt: "2026-01-01", value: 9 }],
      subcutaneous_fat_mass_kg: [{ createdAt: "2026-01-01", value: 14 }],
    },
    recent30Days: {
      body_fat_pct: [
        { createdAt: "2026-05-01", value: 24.555 },
        { createdAt: "2026-06-01", value: 23.444 },
      ],
      fat_mass_kg: [
        { createdAt: "2026-05-01", value: 18 },
        { createdAt: "2026-06-01", value: 18 },
      ],
      muscle_mass_kg: [],
      skeletal_muscle_kg: [],
      visceral_fat: [],
      subcutaneous_fat_mass_kg: [],
    },
  },
  latestBodyComposition: {
    skeletal_muscle_kg: 31,
    water_pct: 58,
    protein_pct: 18,
  },
};

test("insight factor and gauge colors are constrained enums", () => {
  expect(payload.insights.factor.factor).toBe("skeletal_muscle_kg");
  expect(payload.insights.factor.factor_color).toBe("yellow");
  expect(payload.performance.ffmi_gauge.factor_color).toBe("green");
  expect(payload.fat.fat_ratio.factor_color).toBe("yellow");
  expect(payload.muscle.skeletal_muscle_gauge.factor_color).toBe("green");
  expect(payload.insights.key_trend.remark.factor_color).toBe("green");

  const invalidFactor = structuredClone(payload) as any;
  invalidFactor.insights.factor.factor = "unknown_metric";
  expect(insights_schema.safeParse(invalidFactor).success).toBe(false);

  const invalidColor = structuredClone(payload) as any;
  invalidColor.insights.factor.factor_color = "blue";
  expect(insights_schema.safeParse(invalidColor).success).toBe(false);

  const invalidRemarkColor = structuredClone(payload) as any;
  invalidRemarkColor.insights.key_trend.remark.factor_color = "blue";
  expect(insights_schema.safeParse(invalidRemarkColor).success).toBe(false);

  const invalidTrend = structuredClone(payload) as any;
  invalidTrend.insights.key_trend.metric = "water_pct";
  expect(insights_schema.safeParse(invalidTrend).success).toBe(false);

  const oldShape = structuredClone(payload) as any;
  oldShape.insights.overview = insightCard("old overview");
  expect(insights_schema.safeParse(oldShape).success).toBe(false);
});

test("preprocessProfileAiReportPayload resolves the selected insight factor", () => {
  const preprocessed = preprocessProfileAiReportPayload(payload, sources);

  expect(preprocessed.insights.factor.preprocess).toEqual({ value: 31 });

  const missingSource = preprocessProfileAiReportPayload(payload, {
    ...sources,
    latestBodyComposition: null,
  });
  expect(missingSource.insights.factor.preprocess).toEqual({ value: null });
});

test("preprocessProfileAiReportPayload keeps only selected progress trends", () => {
  const preprocessed = preprocessProfileAiReportPayload(payload, sources);

  expect(preprocessed.insights.progress.trends).toEqual([
    "body_fat_pct",
    "fat_mass_kg",
  ]);
  expect(preprocessed.insights.progress.preprocess).toEqual({
    trends: {
      body_fat_pct: [
        { createdAt: "2026-05-01", value: 0 },
        { createdAt: "2026-06-01", value: -1.11 },
      ],
      fat_mass_kg: [
        { createdAt: "2026-05-01", value: 0 },
        { createdAt: "2026-06-01", value: 0 },
      ],
    },
  });
  expect("value" in preprocessed.insights.progress.preprocess).toBe(false);
  expect(preprocessed.insights.progress.comment).toBe("progress comment");
});

test("preprocess attaches only the selected absolute all-time key trend", () => {
  const preprocessed = preprocessProfileAiReportPayload(payload, sources);

  expect(preprocessed.insights.key_trend.metric).toBe("skeletal_muscle_kg");
  expect(preprocessed.insights.key_trend.preprocess).toEqual({
    trends: {
      skeletal_muscle_kg: sources.trendSources.fullHistory.skeletal_muscle_kg,
    },
  });
  expect(preprocessed.insights).toEqual({
    factor: preprocessed.insights.factor,
    key_trend: preprocessed.insights.key_trend,
    progress: preprocessed.insights.progress,
  });
});

test("progress normalization handles empty, sparse, positive, negative, flat, and rounding", () => {
  const raw = [
    { createdAt: "a", value: 10.005 },
    { createdAt: "b", value: 11.239 },
    { createdAt: "c", value: 8.001 },
    { createdAt: "d", value: 10.005 },
  ];
  expect(normalizeProgressTrend([])).toEqual([]);
  expect(normalizeProgressTrend(raw.slice(0, 1))).toEqual([
    { createdAt: "a", value: 0 },
  ]);
  expect(normalizeProgressTrend(raw)).toEqual([
    { createdAt: "a", value: 0 },
    { createdAt: "b", value: 1.23 },
    { createdAt: "c", value: -2 },
    { createdAt: "d", value: 0 },
  ]);
  expect(raw[0]?.value).toBe(10.005);
});

test("trend source assembly is ordered, snapshot-safe, and keeps absolute all-time values", () => {
  const rows = [
    { createdAt: "2026-08-10T00:00:00Z", bodyFatPct: 19, fatMassKg: 14, muscleMassKg: 44, skeletalMuscleKg: 33, visceralFat: 7, subcutaneousFatMassKg: 10 },
    { createdAt: "2026-07-01T00:00:00Z", bodyFatPct: 22, fatMassKg: 16, muscleMassKg: 42, skeletalMuscleKg: 31, visceralFat: 8, subcutaneousFatMassKg: 12 },
    { createdAt: "2026-08-01T00:00:00Z", bodyFatPct: 20, fatMassKg: 15, muscleMassKg: 43, skeletalMuscleKg: 32, visceralFat: 7, subcutaneousFatMassKg: 11 },
  ];
  const trends = buildProfileAiTrendSources(rows, "2026-08-09T00:00:00Z");

  expect(trends.fullHistory.body_fat_pct).toEqual([
    { createdAt: "2026-07-01T00:00:00Z", value: 22 },
    { createdAt: "2026-08-01T00:00:00Z", value: 20 },
  ]);
  expect(trends.recent30Days.skeletal_muscle_kg).toEqual([
    { createdAt: "2026-08-01T00:00:00Z", value: 32 },
  ]);
});

test("sparse trend cards explicitly report insufficient history", () => {
  const sparse = structuredClone(sources);
  sparse.trendSources.fullHistory.skeletal_muscle_kg = [
    { createdAt: "2026-06-01", value: 31 },
  ];
  sparse.trendSources.recent30Days.body_fat_pct = [];
  sparse.trendSources.recent30Days.fat_mass_kg = [
    { createdAt: "2026-06-01", value: 18 },
  ];

  const preprocessed = preprocessProfileAiReportPayload(payload, sparse);
  expect(preprocessed.insights.key_trend.comment).toMatch(/insufficient history/i);
  expect(preprocessed.insights.progress.comment).toMatch(/insufficient history/i);
  expect(preprocessed.insights.progress.preprocess.trends).toEqual({
    body_fat_pct: [],
    fat_mass_kg: [{ createdAt: "2026-06-01", value: 0 }],
  });
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
    value: sources.fatReport.metrics.fatDistribution30dDelta,
    trends: {
      visceralFatIndex: sources.fatReport.last30Days.visceralFatIndex,
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
  expect(preprocessed.muscle.skeletal_muscle_gauge.preprocess).toEqual({
    value: 41,
  });
  expect(preprocessed.muscle.muscle_ratio_trend.preprocess).toEqual({
    value: 56,
    trends: { muscleRatio: sources.muscleReport.last30Days.muscleRatio },
  });
  expect(preprocessed.muscle.bone_mass_trend.preprocess).toEqual({
    value: 12,
    trends: {
      leanNonMuscleMassKg:
        sources.muscleReport.last30Days.leanNonMuscleMassKg,
    },
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

test("formatBoneMassTrendForAgent includes current value and 30-day series", () => {
  const formatted = formatBoneMassTrendForAgent(sources.muscleReport);

  expect(formatted).toContain("Bone Mass Trend");
  expect(formatted).toContain("lean non-muscle");
  expect(formatted).toContain("muscle.bone_mass_trend");
  expect(formatted).toContain("current_kg\t12");
  expect(formatted).toContain("created_at\tvalue_kg");
  expect(formatted).toContain("2026-06-01\t0.1");
});

test("formatBoneMassTrendForAgent reports empty state when no muscle report", () => {
  const formatted = formatBoneMassTrendForAgent(null);

  expect(formatted).toContain("no lean non-muscle");
  expect(formatted).toContain("available yet");
  expect(formatted.includes("current_kg")).toBe(false);
});

test("preprocess bone_mass_trend uses lean non-muscle series", () => {
  const preprocessed = preprocessProfileAiReportPayload(payload, sources);

  expect(preprocessed.muscle.bone_mass_trend.preprocess).toEqual({
    value: 12,
    trends: {
      leanNonMuscleMassKg: sources.muscleReport.last30Days.leanNonMuscleMassKg,
    },
  });
});
