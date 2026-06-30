# Revamp roadmap: AUTISMO to AutiAssist

## New project title

AutiAssist: Autism Support, Screening, and Skill-Building Platform

## Goal

Turn the old quiz-based MERN app into a complete support platform with caregiver profiles, screening sessions, emotion-learning games, progress tracking, optional video-behaviour markers, and reports.

## Safe positioning

The platform should not claim that it diagnoses autism. It should use wording such as:

- screening support
- likelihood indicators
- progress tracking
- behavioural markers
- professional referral recommendation

## Phase 1: Restore and clean

- Upload the restored ZIP to GitHub
- Add `.env.example`
- Add setup docs
- Make the project run locally
- Seed demo questions
- Replace unsafe diagnostic result wording
- Add unified `GameQuestion` model

## Phase 2: Authentication and roles

Add three roles:

- Caregiver
- Clinician
- Admin

Features:

- Register/login
- JWT authentication
- Protected routes
- Admin-only question upload
- Caregiver dashboard
- Clinician review dashboard

## Phase 3: Profiles and screening history

Collections:

- User
- ChildProfile
- AssessmentTemplate
- AssessmentSession

Features:

- Create child/adult profile
- Save screening answers
- Store score and likelihood band
- Show previous assessments
- Add safe disclaimer to every result page

## Phase 4: Emotion-learning games

Upgrade the existing levels:

- Level 1: image emotion recognition
- Level 2: audio emotion recognition
- Level 3: video/social-scenario emotion recognition

Add:

- attempts
- response time
- score history
- difficulty
- hints
- badges
- progress chart

## Phase 5: Webcam practice

Keep face-api.js as practice, not diagnosis.

Add:

- camera consent screen
- start/stop controls
- no raw image storage by default
- session summary
- dominant expression timeline

## Phase 6: ML service

Add a Python FastAPI service for video analysis.

Possible features:

- blink frequency
- face visibility ratio
- head movement variance
- hand movement frequency
- repetitive motion estimate

Output should be behavioural markers, not diagnosis.

## Phase 7: Wellbeing tracker

Weekly caregiver logs:

- sleep
- mood
- sensory overload
- communication difficulty
- social interaction
- distress episodes
- notes

Show trends on the dashboard.

## Phase 8: Reports

Generate reports containing:

- profile details
- screening history
- game progress
- webcam practice summary
- optional video markers
- wellbeing trends
- clinician notes
- disclaimer

## Suggested final architecture

```text
React frontend
  |
Node.js + Express API
  |
MongoDB
  |
Python FastAPI ML service
```

## Suggested future folder structure

```text
autiassist/
  apps/
    web/
    api/
    ml-service/
  packages/
    shared/
  docs/
  docker-compose.yml
  README.md
```

