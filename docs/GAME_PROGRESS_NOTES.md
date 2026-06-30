# Game Progress Tracking

Phase 3 adds saved game attempts for the image, audio, and video emotion-learning activities.

## What is saved

When a logged-in user completes a level, the app stores:

- level number
- score and maximum score
- total questions
- number of correct answers
- accuracy percentage
- optional child profile
- start and completion time
- total duration
- per-question selected answer, correct answer, correctness, and response time

Guest users can still play games, but attempts are not saved.

## New API routes

```text
POST   /api/game-attempts
GET    /api/game-attempts/my
GET    /api/game-attempts/summary
DELETE /api/game-attempts/:id
```

## New frontend page

```text
/game-progress
```

This page shows total attempts, average accuracy, best accuracy, level breakdown, and recent attempts.
