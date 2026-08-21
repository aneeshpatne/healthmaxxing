import { expect, test } from "bun:test";
import { calculateTargetComposition } from "./compositionSummary";

test("maintain keeps current lean mass and changes fat to the target percentage", () => {
  expect(calculateTargetComposition({
    currentLeanMassKg: 60,
    heightCm: 172,
    gender: "male",
    targetBodyFatPct: 18,
    muscularityGoal: "maintain",
  })).toEqual({
    weightKg: 73.17,
    leanMassKg: 60,
    fatMassKg: 13.17,
    bodyFatPct: 18,
    ffmi: 20.28,
    muscularityGoal: "maintain",
  });
});

test("muscular targets gender-aware FFMI without reducing existing lean mass", () => {
  const target = calculateTargetComposition({
    currentLeanMassKg: 60,
    heightCm: 172,
    gender: "male",
    targetBodyFatPct: 18,
    muscularityGoal: "muscular",
  });
  expect(target).toEqual({
    weightKg: 79.37,
    leanMassKg: 65.08,
    fatMassKg: 14.29,
    bodyFatPct: 18,
    ffmi: 22,
    muscularityGoal: "muscular",
  });

  const alreadyAboveTarget = calculateTargetComposition({
    currentLeanMassKg: 70,
    heightCm: 172,
    gender: "male",
    targetBodyFatPct: 18,
    muscularityGoal: "muscular",
  });
  expect(alreadyAboveTarget.leanMassKg).toBe(70);
});
