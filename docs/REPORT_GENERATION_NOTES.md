# Phase 5: Reports

This phase adds a saved report workflow for the caregiver/admin dashboard.

The report combines:

- child profile details
- saved screening result summary
- emotion-game progress summary
- wellbeing tracker summary
- common triggers and helpful strategies
- non-diagnostic recommendations
- a clear safety disclaimer

## API routes

```text
GET    /api/reports/overview?profileId=<id>
GET    /api/reports/my?profileId=<id>
POST   /api/reports/generate
GET    /api/reports/:id
DELETE /api/reports/:id
```

## Frontend route

```text
/reports
```

## Notes for project presentation

Use the report as a review summary, not a diagnosis. The generated recommendations are based only on app data and caregiver-entered logs.

The browser print option can be used to save the report as a PDF without adding another PDF dependency to the project.
