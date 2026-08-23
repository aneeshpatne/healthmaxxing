#if DEBUG
import Foundation

enum FormaUITestScenario: String {
    case metricsLoading = "metrics-loading"
    case metricsError = "metrics-error"
    case metricsPopulated = "metrics-populated"
}

enum FormaFixtures {
    static let populatedReport: InsightReport = {
        let json = #"""
        {
          "reportId": "11111111-1111-1111-1111-111111111111",
          "profileId": "22222222-2222-2222-2222-222222222222",
          "generationStatus": "completed",
          "generationError": null,
          "createdAt": "2026-07-01T10:00:00Z",
          "updatedAt": "2026-07-28T10:00:00Z",
          "data": {
            "insights": {
              "factor": {
                "factor": "Consistency",
                "factor_color": "green",
                "comment": "Your recent readings show steady, sustainable progress.",
                "remark": { "marker": "complement", "text": "Small repeatable actions are compounding." },
                "preprocess": { "value": 82 }
              },
              "overview": {
                "title": "Overview",
                "headline": "Your trend is moving in the right direction.",
                "comment": "Body composition is becoming more balanced over time.",
                "remark": { "marker": "trend_up", "text": "Lean mass is holding while fat ratio eases." }
              },
              "effort_score": {
                "title": "Effort Score",
                "headline": "Strong consistency",
                "score": 84,
                "comment": "Your recent cadence supports durable progress.",
                "remark": { "marker": "complement", "text": "Keep the routine simple and repeatable." }
              }
            },
            "performance": {
              "ffmi_gauge": {
                "title": "Balanced muscularity",
                "comment": "Your fat-free mass is in a healthy performance range.",
                "factor_color": "green",
                "remark": { "marker": "complement", "text": "Maintain strength work and recovery." },
                "preprocess": { "value": 19.8 }
              }
            },
            "fat": {
              "fat_ratio": {
                "title": "Optimal",
                "comment": "Your current body-fat ratio is within the target range.",
                "factor_color": "green",
                "remark": { "marker": "complement", "text": "The overall direction remains favorable." },
                "preprocess": { "value": 17.4 }
              },
              "fat_ratio_trend": {
                "title": "Improving",
                "comment": "Body-fat ratio has eased gradually.",
                "factor_color": "green",
                "remark": { "marker": "trend_down", "text": "The change is gradual and sustainable." },
                "preprocess": {
                  "value": 17.4,
                  "trends": {
                    "fatPercent": [
                      { "createdAt": "2026-07-01T10:00:00Z", "value": 18.2 },
                      { "createdAt": "2026-07-14T10:00:00Z", "value": 17.8 },
                      { "createdAt": "2026-07-28T10:00:00Z", "value": 17.4 }
                    ]
                  }
                }
              }
            },
            "muscle": {
              "skeletal_muscle_gauge": {
                "title": "Strong foundation",
                "comment": "Skeletal muscle ratio is in a healthy range.",
                "factor_color": "green",
                "remark": { "marker": "complement", "text": "Continue progressive strength work." },
                "preprocess": { "value": 41.2 }
              },
              "muscle_mass": {
                "heading": "Muscle Mass History",
                "title": "Stable lean tissue",
                "comment": "Muscle mass has remained steady across recent readings.",
                "factor_color": "green",
                "remark": { "marker": "complement", "text": "Consistency is protecting lean mass." },
                "preprocess": {
                  "value": 31.8,
                  "trends": {
                    "muscleMassKg": [
                      { "createdAt": "2026-07-01T10:00:00Z", "value": 31.4 },
                      { "createdAt": "2026-07-14T10:00:00Z", "value": 31.6 },
                      { "createdAt": "2026-07-28T10:00:00Z", "value": 31.8 }
                    ]
                  }
                }
              }
            }
          }
        }
        """#

        do {
            return try JSONDecoder().decode(InsightReport.self, from: Data(json.utf8))
        } catch {
            preconditionFailure("Invalid populated report fixture: \(error)")
        }
    }()
}
#endif
