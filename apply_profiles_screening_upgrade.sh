#!/usr/bin/env bash
set -euo pipefail

if [ ! -f "package.json" ] || [ ! -d "client/src" ]; then
  echo "Run this script from the autismo-revamp-starter project root."
  exit 1
fi

if [ ! -f "middleware/auth.js" ] || [ ! -f "models/user.js" ]; then
  echo "Auth upgrade is required before this step. Apply apply_auth_upgrade.sh first."
  exit 1
fi

echo "Applying AutiAssist profile and saved-screening upgrade..."

mkdir -p models routes utils client/src/components/Profiles client/src/components/Screening

cat > utils/assessmentTemplates.js <<'NODEEOF'
const childQuestions = [
  {
    id: 'child_point_follow',
    text: 'If you point at something across the room, does your child look at it?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_hearing_concern',
    text: 'Have you ever wondered if your child might be deaf?',
    options: ['Yes', 'No'],
    riskAnswer: 'Yes'
  },
  {
    id: 'child_pretend_play',
    text: 'Does your child play pretend or make-believe?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_climbing',
    text: 'Does your child like climbing on things?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_finger_movements',
    text: 'Does your child make unusual finger movements near their eyes?',
    options: ['Yes', 'No'],
    riskAnswer: 'Yes'
  },
  {
    id: 'child_point_help',
    text: 'Does your child point with one finger to ask for something or to get help?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_interaction',
    text: 'Does your child interact with other children?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_name_response',
    text: 'Does your child respond when you call their name?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_words',
    text: 'Does your child use between one and three words?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_simple_instructions',
    text: 'Does your child understand simple instructions, such as "Where is teddy?"',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_eye_contact',
    text: 'Does your child look you in the eye when you are talking to them?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_copying',
    text: 'Does your child try to copy what you do?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_joint_attention',
    text: 'If you turn your head to look at something, does your child look around to see what you are looking at?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  },
  {
    id: 'child_understands_requests',
    text: 'Does your child understand when you tell them to do something?',
    options: ['Yes', 'No'],
    riskAnswer: 'No'
  }
];

const adultQuestions = [
  {
    id: 'adult_prefer_alone',
    text: 'I often prefer to do things on my own rather than with others.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_same_way',
    text: 'I prefer doing things the same way, such as following a familiar routine.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_absorbed',
    text: 'I become strongly absorbed in specific interests or activities.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_noise_sensitive',
    text: 'I am very sensitive to sounds, textures, lights, or crowded environments.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_politeness_mismatch',
    text: 'People sometimes say I seem rude even when I think I am being polite.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_group_talk',
    text: 'I find it easy to talk in groups of people.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Slightly Disagree', 'Definitely Disagree']
  },
  {
    id: 'adult_things_people',
    text: 'I am more interested in finding out about things than people.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_info_patterns',
    text: 'I find numbers, dates, patterns, or strings of information fascinating.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_routine_change',
    text: 'I find it upsetting when my daily routine is changed unexpectedly.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  },
  {
    id: 'adult_body_language',
    text: 'It is difficult for me to understand other people\'s facial expressions or body language.',
    options: ['Definitely Agree', 'Slightly Agree', 'Slightly Disagree', 'Definitely Disagree'],
    riskAnswers: ['Definitely Agree', 'Slightly Agree']
  }
];

const templates = {
  child: {
    id: 'child-developmental-screener-v1',
    type: 'child',
    title: 'Child developmental screening support',
    version: 1,
    disclaimer: 'This screening summary is not a medical diagnosis. It is only a support tool for organizing concerns and deciding whether professional advice may be useful.',
    questions: childQuestions
  },
  adult: {
    id: 'adult-self-check-v1',
    type: 'adult',
    title: 'Adult autism-related self-check',
    version: 1,
    disclaimer: 'This self-check is not a medical diagnosis. It can help organize concerns before speaking with a qualified professional.',
    questions: adultQuestions
  }
};

function getTemplate(type) {
  return templates[type] || null;
}

function publicTemplate(template) {
  return {
    id: template.id,
    type: template.type,
    title: template.title,
    version: template.version,
    disclaimer: template.disclaimer,
    questions: template.questions.map(question => ({
      id: question.id,
      text: question.text,
      options: question.options
    }))
  };
}

function calculateResult(type, responses) {
  const template = getTemplate(type);

  if (!template) {
    throw new Error('Unknown assessment type.');
  }

  const responseMap = new Map(
    responses.map(response => [String(response.questionId || ''), String(response.answer || '')])
  );

  const scoredResponses = template.questions.map(question => {
    const answer = responseMap.get(question.id) || '';
    const riskAnswers = question.riskAnswers || [question.riskAnswer];
    const isRisk = riskAnswers.includes(answer);

    return {
      questionId: question.id,
      question: question.text,
      answer,
      score: isRisk ? 1 : 0
    };
  });

  const unanswered = scoredResponses.filter(response => !response.answer);
  if (unanswered.length > 0) {
    throw new Error('Please answer all screening questions before submitting.');
  }

  const score = scoredResponses.reduce((total, response) => total + response.score, 0);
  const maxScore = template.questions.length;

  let band = 'low';
  let recommendation = 'Low likelihood indicators. Continue regular monitoring and use professional advice if concerns continue.';

  if (type === 'child') {
    if (score >= 6) {
      band = 'high';
      recommendation = 'High likelihood indicators. A professional developmental evaluation is recommended.';
    } else if (score >= 3) {
      band = 'moderate';
      recommendation = 'Moderate likelihood indicators. Follow-up questions or consultation with a qualified professional is recommended.';
    }
  } else {
    if (score >= 7) {
      band = 'high';
      recommendation = 'High likelihood indicators. Consider a professional autism assessment or referral.';
    } else if (score >= 4) {
      band = 'moderate';
      recommendation = 'Moderate likelihood indicators. Follow-up with a qualified professional may be useful.';
    }
  }

  return {
    template,
    score,
    maxScore,
    band,
    recommendation,
    responses: scoredResponses
  };
}

module.exports = {
  templates,
  getTemplate,
  publicTemplate,
  calculateResult
};
NODEEOF

cat > models/childProfile.js <<'NODEEOF'
const mongoose = require('mongoose');

const childProfileSchema = new mongoose.Schema(
  {
    caregiver: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    name: {
      type: String,
      required: true,
      trim: true,
      minlength: 2
    },
    nickname: {
      type: String,
      trim: true,
      default: ''
    },
    dateOfBirth: {
      type: Date
    },
    gender: {
      type: String,
      enum: ['female', 'male', 'other', 'prefer_not_to_say', ''],
      default: ''
    },
    notes: {
      type: String,
      trim: true,
      maxlength: 1000,
      default: ''
    },
    archived: {
      type: Boolean,
      default: false,
      index: true
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('ChildProfile', childProfileSchema);
NODEEOF

cat > models/assessmentSession.js <<'NODEEOF'
const mongoose = require('mongoose');

const responseSchema = new mongoose.Schema(
  {
    questionId: String,
    question: String,
    answer: String,
    score: Number
  },
  { _id: false }
);

const assessmentSessionSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    profile: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ChildProfile',
      default: null,
      index: true
    },
    assessmentType: {
      type: String,
      enum: ['child', 'adult'],
      required: true,
      index: true
    },
    templateId: {
      type: String,
      required: true
    },
    templateVersion: {
      type: Number,
      required: true
    },
    score: {
      type: Number,
      required: true
    },
    maxScore: {
      type: Number,
      required: true
    },
    band: {
      type: String,
      enum: ['low', 'moderate', 'high'],
      required: true,
      index: true
    },
    recommendation: {
      type: String,
      required: true
    },
    disclaimer: {
      type: String,
      required: true
    },
    responses: [responseSchema]
  },
  { timestamps: true }
);

module.exports = mongoose.model('AssessmentSession', assessmentSessionSchema);
NODEEOF

cat > routes/profiles.js <<'NODEEOF'
const router = require('express').Router();
const ChildProfile = require('../models/childProfile');
const AssessmentSession = require('../models/assessmentSession');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

function ownerQuery(req, extra = {}) {
  if (req.user.role === 'admin') {
    return { ...extra };
  }
  return { caregiver: req.user._id, ...extra };
}

router.get('/', async (req, res) => {
  try {
    const profiles = await ChildProfile.find(ownerQuery(req, { archived: false }))
      .sort({ createdAt: -1 })
      .lean();

    res.json(profiles);
  } catch (error) {
    res.status(500).json({ message: 'Unable to load profiles.', error: error.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const name = String(req.body.name || '').trim();
    const nickname = String(req.body.nickname || '').trim();
    const gender = String(req.body.gender || '').trim();
    const notes = String(req.body.notes || '').trim();
    const dateOfBirth = req.body.dateOfBirth ? new Date(req.body.dateOfBirth) : undefined;

    if (!name) {
      return res.status(400).json({ message: 'Child name is required.' });
    }

    const profile = await ChildProfile.create({
      caregiver: req.user._id,
      name,
      nickname,
      gender,
      notes,
      dateOfBirth
    });

    res.status(201).json(profile);
  } catch (error) {
    res.status(500).json({ message: 'Unable to create profile.', error: error.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const profile = await ChildProfile.findOne(ownerQuery(req, { _id: req.params.id, archived: false })).lean();

    if (!profile) {
      return res.status(404).json({ message: 'Profile not found.' });
    }

    const assessments = await AssessmentSession.find({ profile: profile._id })
      .sort({ createdAt: -1 })
      .limit(10)
      .lean();

    res.json({ profile, assessments });
  } catch (error) {
    res.status(500).json({ message: 'Unable to load profile.', error: error.message });
  }
});

router.patch('/:id', async (req, res) => {
  try {
    const updates = {};
    ['name', 'nickname', 'gender', 'notes'].forEach(field => {
      if (Object.prototype.hasOwnProperty.call(req.body, field)) {
        updates[field] = String(req.body[field] || '').trim();
      }
    });

    if (Object.prototype.hasOwnProperty.call(req.body, 'dateOfBirth')) {
      updates.dateOfBirth = req.body.dateOfBirth ? new Date(req.body.dateOfBirth) : undefined;
    }

    const profile = await ChildProfile.findOneAndUpdate(
      ownerQuery(req, { _id: req.params.id, archived: false }),
      updates,
      { new: true, runValidators: true }
    );

    if (!profile) {
      return res.status(404).json({ message: 'Profile not found.' });
    }

    res.json(profile);
  } catch (error) {
    res.status(500).json({ message: 'Unable to update profile.', error: error.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const profile = await ChildProfile.findOneAndUpdate(
      ownerQuery(req, { _id: req.params.id, archived: false }),
      { archived: true },
      { new: true }
    );

    if (!profile) {
      return res.status(404).json({ message: 'Profile not found.' });
    }

    res.json({ message: 'Profile archived.', profile });
  } catch (error) {
    res.status(500).json({ message: 'Unable to archive profile.', error: error.message });
  }
});

module.exports = router;
NODEEOF

cat > routes/assessmentSessions.js <<'NODEEOF'
const router = require('express').Router();
const AssessmentSession = require('../models/assessmentSession');
const ChildProfile = require('../models/childProfile');
const { requireAuth } = require('../middleware/auth');
const { templates, publicTemplate, calculateResult } = require('../utils/assessmentTemplates');

router.use(requireAuth);

function sessionOwnerQuery(req, extra = {}) {
  if (req.user.role === 'admin') {
    return { ...extra };
  }
  return { user: req.user._id, ...extra };
}

async function assertProfileAccess(req, profileId) {
  if (!profileId) {
    return null;
  }

  const query = req.user.role === 'admin'
    ? { _id: profileId, archived: false }
    : { _id: profileId, caregiver: req.user._id, archived: false };

  const profile = await ChildProfile.findOne(query);
  if (!profile) {
    const error = new Error('Profile not found or access denied.');
    error.status = 404;
    throw error;
  }

  return profile;
}

router.get('/templates', (req, res) => {
  res.json({
    child: publicTemplate(templates.child),
    adult: publicTemplate(templates.adult)
  });
});

router.get('/my', async (req, res) => {
  try {
    const sessions = await AssessmentSession.find(sessionOwnerQuery(req))
      .populate('profile', 'name nickname')
      .sort({ createdAt: -1 })
      .limit(30)
      .lean();

    res.json(sessions);
  } catch (error) {
    res.status(500).json({ message: 'Unable to load assessment history.', error: error.message });
  }
});

router.get('/profile/:profileId', async (req, res) => {
  try {
    await assertProfileAccess(req, req.params.profileId);

    const sessions = await AssessmentSession.find({ profile: req.params.profileId })
      .populate('profile', 'name nickname')
      .sort({ createdAt: -1 })
      .lean();

    res.json(sessions);
  } catch (error) {
    res.status(error.status || 500).json({ message: error.message || 'Unable to load profile assessments.' });
  }
});

router.post('/', async (req, res) => {
  try {
    const assessmentType = String(req.body.assessmentType || '').trim();
    const profileId = req.body.profileId || null;
    const incomingResponses = Array.isArray(req.body.responses) ? req.body.responses : [];

    if (!['child', 'adult'].includes(assessmentType)) {
      return res.status(400).json({ message: 'Use child or adult as the assessment type.' });
    }

    if (assessmentType === 'child' && !profileId) {
      return res.status(400).json({ message: 'Select a child profile before submitting a child screening.' });
    }

    await assertProfileAccess(req, profileId);

    const result = calculateResult(assessmentType, incomingResponses);

    const session = await AssessmentSession.create({
      user: req.user._id,
      profile: profileId,
      assessmentType,
      templateId: result.template.id,
      templateVersion: result.template.version,
      score: result.score,
      maxScore: result.maxScore,
      band: result.band,
      recommendation: result.recommendation,
      disclaimer: result.template.disclaimer,
      responses: result.responses
    });

    const populated = await AssessmentSession.findById(session._id)
      .populate('profile', 'name nickname')
      .lean();

    res.status(201).json(populated);
  } catch (error) {
    res.status(error.status || 500).json({ message: error.message || 'Unable to save screening result.' });
  }
});

module.exports = router;
NODEEOF

node <<'NODE'
const fs = require('fs');
const file = 'index.js';
let text = fs.readFileSync(file, 'utf8');
if (!text.includes("app.use('/api/profiles'")) {
  text = text.replace(
    "// New unified quiz API for the revamp.\napp.use('/api/game-questions', require('./routes/gameQuestions'));",
    "// Profile and saved screening APIs.\napp.use('/api/profiles', require('./routes/profiles'));\napp.use('/api/assessment-sessions', require('./routes/assessmentSessions'));\n\n// New unified quiz API for the revamp.\napp.use('/api/game-questions', require('./routes/gameQuestions'));"
  );
  fs.writeFileSync(file, text);
}
NODE

cat > client/src/components/Profiles/Profiles.js <<'REACTEOF'
import React, { Component } from 'react';
import axios from 'axios';
import { Link } from 'react-router-dom';
import classes from './Profiles.module.css';

class Profiles extends Component {
    state = {
        profiles: [],
        name: '',
        nickname: '',
        dateOfBirth: '',
        gender: '',
        notes: '',
        loading: true,
        submitting: false,
        error: '',
        success: ''
    };

    componentDidMount() {
        this.loadProfiles();
    }

    loadProfiles = async () => {
        this.setState({ loading: true, error: '' });

        try {
            const response = await axios.get('/api/profiles');
            this.setState({ profiles: response.data, loading: false });
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to load profiles.';
            this.setState({ error: message, loading: false });
        }
    };

    inputHandler = event => {
        this.setState({ [event.target.name]: event.target.value, error: '', success: '' });
    };

    submitHandler = async event => {
        event.preventDefault();
        this.setState({ submitting: true, error: '', success: '' });

        try {
            await axios.post('/api/profiles', {
                name: this.state.name,
                nickname: this.state.nickname,
                dateOfBirth: this.state.dateOfBirth,
                gender: this.state.gender,
                notes: this.state.notes
            });

            this.setState({
                name: '',
                nickname: '',
                dateOfBirth: '',
                gender: '',
                notes: '',
                submitting: false,
                success: 'Profile created successfully.'
            });
            this.loadProfiles();
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to create profile.';
            this.setState({ error: message, submitting: false });
        }
    };

    archiveProfile = async profileId => {
        const confirmed = window.confirm('Archive this profile? Saved screening history will remain available in the database.');
        if (!confirmed) {
            return;
        }

        try {
            await axios.delete(`/api/profiles/${profileId}`);
            this.loadProfiles();
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to archive profile.';
            this.setState({ error: message });
        }
    };

    formatDate(date) {
        if (!date) {
            return 'Not added';
        }
        return new Date(date).toLocaleDateString();
    }

    render() {
        return (
            <div className={classes.Page}>
                <section className={classes.Header}>
                    <h1>Child profiles</h1>
                    <p>Create profiles so screening results, game progress, and wellbeing logs can be linked to the right child.</p>
                </section>

                <section className={classes.Layout}>
                    <form className={classes.Card} onSubmit={this.submitHandler}>
                        <h2>Add profile</h2>

                        {this.state.error ? <div className={classes.Error}>{this.state.error}</div> : null}
                        {this.state.success ? <div className={classes.Success}>{this.state.success}</div> : null}

                        <label>Child name</label>
                        <input name="name" value={this.state.name} onChange={this.inputHandler} required />

                        <label>Nickname</label>
                        <input name="nickname" value={this.state.nickname} onChange={this.inputHandler} />

                        <label>Date of birth</label>
                        <input name="dateOfBirth" type="date" value={this.state.dateOfBirth} onChange={this.inputHandler} />

                        <label>Gender</label>
                        <select name="gender" value={this.state.gender} onChange={this.inputHandler}>
                            <option value="">Select</option>
                            <option value="female">Female</option>
                            <option value="male">Male</option>
                            <option value="other">Other</option>
                            <option value="prefer_not_to_say">Prefer not to say</option>
                        </select>

                        <label>Notes</label>
                        <textarea
                            name="notes"
                            rows="4"
                            value={this.state.notes}
                            onChange={this.inputHandler}
                            placeholder="Optional caregiver notes, communication preferences, or sensory considerations."
                        />

                        <button type="submit" disabled={this.state.submitting}>
                            {this.state.submitting ? 'Saving...' : 'Save profile'}
                        </button>
                    </form>

                    <div className={classes.List}>
                        <div className={classes.ListHeader}>
                            <h2>Saved profiles</h2>
                            <Link to="/screening/new">Start screening</Link>
                        </div>

                        {this.state.loading ? <p>Loading profiles...</p> : null}

                        {!this.state.loading && this.state.profiles.length === 0 ? (
                            <div className={classes.Empty}>
                                <h3>No profiles yet</h3>
                                <p>Add your first child profile to save screening history.</p>
                            </div>
                        ) : null}

                        {this.state.profiles.map(profile => (
                            <article key={profile._id} className={classes.ProfileCard}>
                                <div>
                                    <h3>{profile.name}</h3>
                                    <p>Nickname: {profile.nickname || 'Not added'}</p>
                                    <p>Date of birth: {this.formatDate(profile.dateOfBirth)}</p>
                                    <p>Gender: {profile.gender ? profile.gender.replace(/_/g, ' ') : 'Not added'}</p>
                                    {profile.notes ? <p className={classes.Notes}>{profile.notes}</p> : null}
                                </div>
                                <button type="button" onClick={() => this.archiveProfile(profile._id)}>Archive</button>
                            </article>
                        ))}
                    </div>
                </section>
            </div>
        );
    }
}

export default Profiles;
REACTEOF

cat > client/src/components/Profiles/Profiles.module.css <<'CSSEOF'
.Page {
    min-height: calc(100vh - 56px);
    padding: 96px 32px 48px;
    background: #20262f;
    color: #ffffff;
}

.Header,
.Layout {
    max-width: 1120px;
    margin: 0 auto;
}

.Header {
    margin-bottom: 24px;
}

.Header h1 {
    margin: 0 0 8px;
    font-size: 36px;
}

.Header p {
    margin: 0;
    color: #d6e4e2;
    line-height: 1.5;
}

.Layout {
    display: grid;
    grid-template-columns: minmax(280px, 380px) 1fr;
    gap: 22px;
    align-items: start;
}

.Card,
.ProfileCard,
.Empty {
    background: #ffffff;
    color: #20262f;
    border-radius: 12px;
    padding: 22px;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.22);
}

.Card h2,
.ListHeader h2,
.ProfileCard h3 {
    margin: 0 0 12px;
    color: #144C52;
}

.Card label {
    display: block;
    font-weight: 700;
    margin: 14px 0 6px;
}

.Card input,
.Card select,
.Card textarea {
    width: 100%;
    border: 1px solid #c9d7d4;
    border-radius: 6px;
    padding: 10px;
    font: inherit;
    box-sizing: border-box;
}

.Card button,
.ProfileCard button,
.ListHeader a {
    display: inline-block;
    border: 0;
    border-radius: 6px;
    background: #144C52;
    color: #ffffff;
    text-decoration: none;
    font-weight: 700;
    padding: 10px 14px;
    cursor: pointer;
    font-size: 14px;
}

.Card button {
    width: 100%;
    margin-top: 18px;
}

.Card button:disabled {
    opacity: 0.7;
    cursor: not-allowed;
}

.ListHeader {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 14px;
}

.ProfileCard {
    margin-bottom: 14px;
    display: flex;
    justify-content: space-between;
    gap: 16px;
}

.ProfileCard p {
    margin: 4px 0;
    color: #4c5965;
}

.ProfileCard button {
    align-self: flex-start;
    background: #8d2b2b;
}

.Notes {
    margin-top: 10px !important;
    padding-top: 10px;
    border-top: 1px solid #e5eeee;
}

.Error,
.Success {
    border-radius: 6px;
    padding: 10px;
    margin-bottom: 12px;
    font-weight: 700;
}

.Error {
    background: #ffe2e2;
    color: #7d1c1c;
}

.Success {
    background: #ddf7e3;
    color: #145c2c;
}

@media (max-width: 850px) {
    .Layout {
        grid-template-columns: 1fr;
    }

    .ProfileCard {
        flex-direction: column;
    }
}
CSSEOF

cat > client/src/components/Screening/Screening.js <<'REACTEOF'
import React, { Component } from 'react';
import axios from 'axios';
import { Link } from 'react-router-dom';
import classes from './Screening.module.css';

class Screening extends Component {
    state = {
        templates: null,
        profiles: [],
        history: [],
        assessmentType: 'child',
        profileId: '',
        answers: {},
        result: null,
        loading: true,
        submitting: false,
        error: ''
    };

    componentDidMount() {
        this.loadData();
    }

    loadData = async () => {
        this.setState({ loading: true, error: '' });

        try {
            const [templatesResponse, profilesResponse, historyResponse] = await Promise.all([
                axios.get('/api/assessment-sessions/templates'),
                axios.get('/api/profiles'),
                axios.get('/api/assessment-sessions/my')
            ]);

            const firstProfile = profilesResponse.data[0] ? profilesResponse.data[0]._id : '';

            this.setState({
                templates: templatesResponse.data,
                profiles: profilesResponse.data,
                history: historyResponse.data,
                profileId: firstProfile,
                loading: false
            });
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to load screening data.';
            this.setState({ error: message, loading: false });
        }
    };

    changeType = event => {
        const assessmentType = event.target.value;
        this.setState({ assessmentType, answers: {}, result: null, error: '' });
    };

    changeProfile = event => {
        this.setState({ profileId: event.target.value, result: null, error: '' });
    };

    selectAnswer = (questionId, answer) => {
        this.setState(prevState => ({
            answers: {
                ...prevState.answers,
                [questionId]: answer
            },
            error: ''
        }));
    };

    submitHandler = async event => {
        event.preventDefault();

        const template = this.state.templates[this.state.assessmentType];
        const missing = template.questions.some(question => !this.state.answers[question.id]);

        if (missing) {
            this.setState({ error: 'Please answer all questions before submitting.' });
            return;
        }

        if (this.state.assessmentType === 'child' && !this.state.profileId) {
            this.setState({ error: 'Create or select a child profile before submitting.' });
            return;
        }

        this.setState({ submitting: true, error: '', result: null });

        try {
            const response = await axios.post('/api/assessment-sessions', {
                assessmentType: this.state.assessmentType,
                profileId: this.state.assessmentType === 'child' ? this.state.profileId : null,
                responses: template.questions.map(question => ({
                    questionId: question.id,
                    answer: this.state.answers[question.id]
                }))
            });

            const historyResponse = await axios.get('/api/assessment-sessions/my');

            this.setState({
                result: response.data,
                history: historyResponse.data,
                submitting: false
            });
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to save screening result.';
            this.setState({ error: message, submitting: false });
        }
    };

    resetForm = () => {
        this.setState({ answers: {}, result: null, error: '' });
        window.scrollTo(0, 0);
    };

    bandClass(band) {
        if (band === 'high') {
            return classes.High;
        }
        if (band === 'moderate') {
            return classes.Moderate;
        }
        return classes.Low;
    }

    render() {
        const template = this.state.templates ? this.state.templates[this.state.assessmentType] : null;
        const completedCount = template
            ? template.questions.filter(question => this.state.answers[question.id]).length
            : 0;

        return (
            <div className={classes.Page}>
                <section className={classes.Header}>
                    <h1>Saved screening support</h1>
                    <p>Complete a non-diagnostic questionnaire and save the result to your account history.</p>
                </section>

                {this.state.loading ? <div className={classes.Notice}>Loading screening module...</div> : null}
                {this.state.error ? <div className={classes.Error}>{this.state.error}</div> : null}

                {!this.state.loading && template ? (
                    <section className={classes.Layout}>
                        <form className={classes.Card} onSubmit={this.submitHandler}>
                            <div className={classes.TopControls}>
                                <label>
                                    Screening type
                                    <select value={this.state.assessmentType} onChange={this.changeType}>
                                        <option value="child">Child screening</option>
                                        <option value="adult">Adult self-check</option>
                                    </select>
                                </label>

                                {this.state.assessmentType === 'child' ? (
                                    <label>
                                        Child profile
                                        <select value={this.state.profileId} onChange={this.changeProfile}>
                                            <option value="">Select profile</option>
                                            {this.state.profiles.map(profile => (
                                                <option key={profile._id} value={profile._id}>{profile.name}</option>
                                            ))}
                                        </select>
                                    </label>
                                ) : null}
                            </div>

                            {this.state.assessmentType === 'child' && this.state.profiles.length === 0 ? (
                                <div className={classes.Warning}>
                                    Create a child profile before saving child screening results. <Link to="/profiles">Add profile</Link>
                                </div>
                            ) : null}

                            <div className={classes.TemplateHeader}>
                                <h2>{template.title}</h2>
                                <p>{completedCount}/{template.questions.length} answered</p>
                            </div>

                            <p className={classes.Disclaimer}>{template.disclaimer}</p>

                            {template.questions.map((question, index) => (
                                <article key={question.id} className={classes.Question}>
                                    <h3>{index + 1}. {question.text}</h3>
                                    <div className={classes.Options}>
                                        {question.options.map(option => (
                                            <button
                                                key={option}
                                                type="button"
                                                className={this.state.answers[question.id] === option ? classes.Selected : ''}
                                                onClick={() => this.selectAnswer(question.id, option)}
                                            >
                                                {option}
                                            </button>
                                        ))}
                                    </div>
                                </article>
                            ))}

                            <button className={classes.SubmitButton} type="submit" disabled={this.state.submitting}>
                                {this.state.submitting ? 'Saving result...' : 'Save screening result'}
                            </button>
                        </form>

                        <aside className={classes.SidePanel}>
                            {this.state.result ? (
                                <div className={classes.ResultCard}>
                                    <span className={`${classes.Band} ${this.bandClass(this.state.result.band)}`}>
                                        {this.state.result.band} likelihood indicators
                                    </span>
                                    <h2>Score: {this.state.result.score}/{this.state.result.maxScore}</h2>
                                    <p>{this.state.result.recommendation}</p>
                                    <p className={classes.SmallText}>{this.state.result.disclaimer}</p>
                                    <button type="button" onClick={this.resetForm}>Start another screening</button>
                                </div>
                            ) : (
                                <div className={classes.ResultCard}>
                                    <h2>Result will appear here</h2>
                                    <p>After submission, the score band and recommendation will be saved to your history.</p>
                                </div>
                            )}

                            <div className={classes.HistoryCard}>
                                <h2>Recent history</h2>
                                {this.state.history.length === 0 ? <p>No saved screenings yet.</p> : null}

                                {this.state.history.slice(0, 6).map(session => (
                                    <div key={session._id} className={classes.HistoryItem}>
                                        <strong>{session.assessmentType === 'child' ? 'Child screening' : 'Adult self-check'}</strong>
                                        <span className={`${classes.HistoryBand} ${this.bandClass(session.band)}`}>{session.band}</span>
                                        <p>{session.profile ? `Profile: ${session.profile.name}` : 'No child profile linked'}</p>
                                        <p>Score: {session.score}/{session.maxScore}</p>
                                        <small>{new Date(session.createdAt).toLocaleString()}</small>
                                    </div>
                                ))}
                            </div>
                        </aside>
                    </section>
                ) : null}
            </div>
        );
    }
}

export default Screening;
REACTEOF

cat > client/src/components/Screening/Screening.module.css <<'CSSEOF'
.Page {
    min-height: calc(100vh - 56px);
    padding: 96px 32px 48px;
    background: #20262f;
    color: #ffffff;
}

.Header,
.Layout,
.Notice,
.Error {
    max-width: 1120px;
    margin-left: auto;
    margin-right: auto;
}

.Header {
    margin-bottom: 24px;
}

.Header h1 {
    margin: 0 0 8px;
    font-size: 36px;
}

.Header p {
    margin: 0;
    color: #d6e4e2;
    line-height: 1.5;
}

.Layout {
    display: grid;
    grid-template-columns: 1fr 340px;
    gap: 22px;
    align-items: start;
}

.Card,
.ResultCard,
.HistoryCard,
.Notice,
.Error {
    background: #ffffff;
    color: #20262f;
    border-radius: 12px;
    padding: 22px;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.22);
}

.Error {
    margin-bottom: 16px;
    background: #ffe2e2;
    color: #7d1c1c;
    font-weight: 700;
}

.TopControls {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 14px;
    margin-bottom: 18px;
}

.TopControls label {
    display: flex;
    flex-direction: column;
    gap: 6px;
    font-weight: 700;
}

.TopControls select {
    border: 1px solid #c9d7d4;
    border-radius: 6px;
    padding: 10px;
    font: inherit;
}

.Warning {
    background: #fff4d8;
    color: #6c4b00;
    padding: 12px;
    border-radius: 8px;
    margin-bottom: 16px;
    font-weight: 700;
}

.Warning a {
    color: #144C52;
}

.TemplateHeader {
    display: flex;
    justify-content: space-between;
    gap: 16px;
    align-items: center;
}

.TemplateHeader h2 {
    margin: 0;
    color: #144C52;
}

.TemplateHeader p {
    margin: 0;
    font-weight: 700;
}

.Disclaimer,
.SmallText {
    background: #eef7f5;
    color: #38524e;
    border-radius: 8px;
    padding: 12px;
    line-height: 1.5;
}

.Question {
    border-top: 1px solid #e5eeee;
    padding: 18px 0;
}

.Question h3 {
    margin: 0 0 12px;
    font-size: 18px;
    line-height: 1.4;
}

.Options {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
}

.Options button,
.SubmitButton,
.ResultCard button {
    border: 0;
    border-radius: 6px;
    background: #e8eeee;
    color: #20262f;
    padding: 10px 14px;
    cursor: pointer;
    font-weight: 700;
}

.Options button.Selected {
    background: #144C52;
    color: #ffffff;
}

.SubmitButton,
.ResultCard button {
    background: #144C52;
    color: #ffffff;
    width: 100%;
    margin-top: 12px;
}

.SubmitButton:disabled {
    opacity: 0.7;
    cursor: not-allowed;
}

.SidePanel {
    display: flex;
    flex-direction: column;
    gap: 18px;
}

.ResultCard h2,
.HistoryCard h2 {
    margin: 12px 0;
    color: #144C52;
}

.Band,
.HistoryBand {
    display: inline-block;
    border-radius: 999px;
    padding: 6px 10px;
    color: #ffffff;
    font-weight: 800;
    text-transform: capitalize;
}

.Low {
    background: #237a39;
}

.Moderate {
    background: #b06b00;
}

.High {
    background: #a32d2d;
}

.HistoryItem {
    border-top: 1px solid #e5eeee;
    padding: 12px 0;
}

.HistoryItem strong {
    display: block;
    margin-bottom: 8px;
}

.HistoryItem p {
    margin: 4px 0;
    color: #4c5965;
}

.HistoryItem small {
    color: #6d7a85;
}

.HistoryBand {
    font-size: 12px;
    padding: 4px 8px;
}

@media (max-width: 950px) {
    .Layout {
        grid-template-columns: 1fr;
    }
}
CSSEOF

node <<'NODE'
const fs = require('fs');
const file = 'client/src/App.js';
let text = fs.readFileSync(file, 'utf8');
if (!text.includes("./components/Profiles/Profiles")) {
  text = text.replace(
    "import Dashboard from './components/Dashboard/Dashboard';",
    "import Dashboard from './components/Dashboard/Dashboard';\nimport Profiles from './components/Profiles/Profiles';\nimport Screening from './components/Screening/Screening';"
  );
}
if (!text.includes('path="/profiles"')) {
  text = text.replace(
    '<ProtectedRoute path="/dashboard" exact component={Dashboard} />',
    '<ProtectedRoute path="/dashboard" exact component={Dashboard} />\n                <ProtectedRoute path="/profiles" exact component={Profiles} />\n                <ProtectedRoute path="/screening/new" exact component={Screening} />'
  );
}
fs.writeFileSync(file, text);
NODE

node <<'NODE'
const fs = require('fs');
const file = 'client/src/components/Dashboard/Dashboard.js';
let text = fs.readFileSync(file, 'utf8');
if (!text.includes('Child profiles')) {
  text = text.replace(
    "<section className={classes.Grid}>",
    "<section className={classes.Grid}>\n                    <div className={classes.Card}>\n                        <h2>Child profiles</h2>\n                        <p>Create child profiles so screenings and future progress tracking are saved properly.</p>\n                        <Link to=\"/profiles\">Manage profiles</Link>\n                    </div>"
  );
}
text = text.replace(
  "<Link to=\"/questionarie\">Open screening</Link>",
  "<Link to=\"/screening/new\">Start saved screening</Link>"
);
fs.writeFileSync(file, text);
NODE

node <<'NODE'
const fs = require('fs');
const file = 'client/src/components/Navigation/NavigationItems/NavigationItems.js';
let text = fs.readFileSync(file, 'utf8');
text = text.replace(
  '<NavigationItem link="/questionarie">Screening Tool</NavigationItem>',
  '<NavigationItem link={auth.user ? "/screening/new" : "/questionarie"}>Screening Tool</NavigationItem>\n                    {auth.user ? <NavigationItem link="/profiles">Profiles</NavigationItem> : null}'
);
fs.writeFileSync(file, text);
NODE

node <<'NODE'
const fs = require('fs');
const file = 'client/src/components/Navigation/SideDrawer/SideDrawer.js';
let text = fs.readFileSync(file, 'utf8');
text = text.replace(
  '<NavigationItem link="/questionarie">Screening Tool</NavigationItem>',
  '<NavigationItem link={auth.user ? "/screening/new" : "/questionarie"}>Screening Tool</NavigationItem>\n                        {auth.user ? <NavigationItem link="/profiles">Profiles</NavigationItem> : null}'
);
fs.writeFileSync(file, text);
NODE

echo "Profile and saved-screening upgrade files added."
echo "Next commands:"
echo "  export NODE_OPTIONS=--openssl-legacy-provider"
echo "  npm run dev"
echo "Then test:"
echo "  http://localhost:3000/profiles"
echo "  http://localhost:3000/screening/new"
