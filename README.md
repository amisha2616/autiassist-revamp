# AutiAssist Revamp Starter

This repository restores the original **AUTISMO** MERN project from ZIP and prepares it for a BTech-level revamp.

The original app helps users practice emotion recognition through image, audio, and video quiz levels. This starter keeps that base and adds setup documentation, safer result wording, demo seed data, and a unified question API.

## Current features

- Landing page
- Image emotion quiz
- Audio emotion quiz
- Video/social scenario quiz
- Webcam-based facial expression practice using face-api.js
- Child and adult screening-style questionnaires
- Blog page
- Admin-style upload screen for quiz questions
- MongoDB-backed CRUD API for game questions

## Important wording note

This project should be described as a **support and screening platform**, not a diagnostic tool. Autism diagnosis requires professional evaluation. The app result pages should only show likelihood indicators and recommendations for follow-up.

## Tech stack

- MongoDB
- Express.js
- React.js
- Node.js
- face-api.js
- Python FastAPI starter folder for future ML/video analysis

## Quick start

Read the full setup guide first:

```text
SETUP.md
```

Basic commands:

```bash
cp .env.example .env
npm run install:all
npm run seed
npm run dev
```

Frontend:

```text
http://localhost:3000
```

Backend health check:

```text
http://localhost:5000/api/health
```

## GitHub upload

Read:

```text
GITHUB_UPLOAD_STEPS.md
```

Suggested repository name:

```text
autiassist-revamp
```

## Revamp roadmap

Read:

```text
docs/REVAMP_ROADMAP.md
```

Recommended final modules:

- Authentication and roles
- Caregiver profiles
- Clinician dashboard
- Screening history
- Emotion game progress tracking
- Webcam practice summaries
- Optional video behaviour marker extraction
- Wellbeing tracker
- PDF-style reports

## Main API routes

New unified game API:

```text
GET    /api/game-questions
GET    /api/game-questions?level=1
POST   /api/game-questions
PUT    /api/game-questions/:id
DELETE /api/game-questions/:id
```

Legacy APIs are still available during migration:

```text
/levelOne
/levelTwo
/levelThree
```

## Demo data

Demo assets are stored in:

```text
client/public/demo-assets/
```

Seed them into MongoDB with:

```bash
npm run seed
```

