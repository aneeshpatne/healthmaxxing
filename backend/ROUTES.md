# Active HTTP surface

The iOS request types in `ios/Forma/Networking` are the consumer inventory.
Response schemas and screen/report structure are unchanged.

| Method | Route | Consumer |
| --- | --- | --- |
| GET | /health | Operational database health check |
| POST | /client/register/profiles/v2 | CreateClientProfileRequest |
| PATCH | /client/profiles/:profileId | UpdateClientProfileRequest |
| GET | /client/profiles | GetClientProfilesRequest |
| GET | /client/profiles/:profileId/insights/jobs/active | GetActiveInsightJobsRequest |
| GET | /client/profiles/:profileId/insights/jobs/:jobId/wait | WaitForInsightJobRequest |
| GET | /client/profiles/:profileId/insights/report-ids/latest | GetLatestInsightReportIdsRequest |
| GET | /client/profiles/:profileId/insights/:reportId | GetInsightReportRequest |
| POST | /ingest/add_measurement/v2 | AddMeasurementRequest |
| POST | /client/food/analyze | AnalyzeFoodRequest |
| POST | /client/food/confirm | ConfirmFoodRequest |
| GET | /client/food/saved/:profileId | Saved food request |
| GET | /client/food/dashboard/:profileId | Food dashboard request |

## Retired routes

These have no callers in the checked-in frontend and are no longer registered. Older
clients or external integrations using these routes need to migrate before deploy.
Internal database/calculation helpers remain available to workers and scripts.

- `/client/register`
- `/client/register/profiles`
- `/client/register/metadata`
- `/client/users`
- `/client/profiles/:profileId/essentials`
- `/client/profiles/:profileId/performance`
- `/client/profiles/:profileId/fat`
- `/client/profiles/:profileId/muscle`
- `/client/profiles/:profileId/insights`
- `/client/profiles/:profileId/insights/recent`
- `/client/body-measurements`
- `/client/body-measurements/:profileId`
- `/client/body-composition/trends`
- `/client/start`
- `/client/weight/:profileId`
- `/ingest/workouts`
- `/ingest/backfill_body_composition`
- `/ingest/add_measurement`

The unused WebSocket registration is removed; report updates use HTTP long polling.
Disconnected long polls stop querying after the current one-second interval.
