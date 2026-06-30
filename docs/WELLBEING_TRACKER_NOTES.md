# Phase 4: Wellbeing Tracker

This phase adds caregiver wellbeing logs linked to child profiles.

The tracker records:

- sleep quality
- sensory overload
- communication ease
- social interaction
- mood
- distress episodes
- possible triggers
- helpful strategies
- caregiver notes

The generated score is only a daily summary indicator. It is not a diagnostic score and should not be presented as medical evidence by itself.

## API routes

```text
POST   /api/wellbeing-logs
GET    /api/wellbeing-logs/my
GET    /api/wellbeing-logs/summary
DELETE /api/wellbeing-logs/:id
```

## Frontend route

```text
/wellbeing
```
