#!/usr/bin/env bash
set -e

if [ ! -f package.json ] || [ ! -d client/src ]; then
  echo "Run this script from the project root folder, for example: ~/Downloads/autismo-revamp-starter"
  exit 1
fi

echo "Applying Phase 3: game attempt tracking and progress dashboard..."

mkdir -p models routes client/src/components/GameProgress

cat > models/gameAttempt.js <<'MODEL'
const mongoose = require('mongoose');

const responseSchema = new mongoose.Schema(
  {
    question: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'GameQuestion',
      default: null
    },
    questionText: {
      type: String,
      trim: true,
      default: ''
    },
    mediaType: {
      type: String,
      enum: ['image', 'audio', 'video', 'text', ''],
      default: ''
    },
    selectedAnswer: {
      type: String,
      trim: true,
      required: true
    },
    correctAnswer: {
      type: String,
      trim: true,
      required: true
    },
    isCorrect: {
      type: Boolean,
      required: true
    },
    responseTimeMs: {
      type: Number,
      min: 0,
      default: 0
    }
  },
  { _id: false }
);

const gameAttemptSchema = new mongoose.Schema(
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
    level: {
      type: Number,
      enum: [1, 2, 3],
      required: true,
      index: true
    },
    score: {
      type: Number,
      required: true,
      min: 0
    },
    maxScore: {
      type: Number,
      required: true,
      min: 1
    },
    totalQuestions: {
      type: Number,
      required: true,
      min: 1
    },
    correctAnswers: {
      type: Number,
      required: true,
      min: 0
    },
    accuracy: {
      type: Number,
      required: true,
      min: 0,
      max: 100,
      index: true
    },
    startedAt: {
      type: Date,
      required: true
    },
    completedAt: {
      type: Date,
      required: true,
      index: true
    },
    durationMs: {
      type: Number,
      min: 0,
      default: 0
    },
    responses: [responseSchema]
  },
  { timestamps: true }
);

gameAttemptSchema.pre('validate', function setDerivedFields(next) {
  if (!this.maxScore && this.totalQuestions) {
    this.maxScore = this.totalQuestions * 10;
  }

  if (!Number.isFinite(this.correctAnswers) && Array.isArray(this.responses)) {
    this.correctAnswers = this.responses.filter(response => response.isCorrect).length;
  }

  if (this.totalQuestions) {
    const computedAccuracy = (this.correctAnswers / this.totalQuestions) * 100;
    this.accuracy = Math.round(computedAccuracy * 100) / 100;
  }

  if (!this.durationMs && this.startedAt && this.completedAt) {
    this.durationMs = Math.max(0, this.completedAt.getTime() - this.startedAt.getTime());
  }

  next();
});

module.exports = mongoose.model('GameAttempt', gameAttemptSchema);
MODEL

cat > routes/gameAttempts.js <<'ROUTE'
const router = require('express').Router();
const mongoose = require('mongoose');
const GameAttempt = require('../models/gameAttempt');
const ChildProfile = require('../models/childProfile');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

function toPositiveInt(value, fallback, max) {
  const number = Number(value);
  if (!Number.isFinite(number) || number <= 0) {
    return fallback;
  }
  return Math.min(Math.floor(number), max);
}

function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(String(id));
}

async function ensureProfileAccess(req, profileId) {
  if (!profileId) {
    return null;
  }

  if (!isValidObjectId(profileId)) {
    const error = new Error('Invalid profile id.');
    error.statusCode = 400;
    throw error;
  }

  const query = {
    _id: profileId,
    archived: false
  };

  if (req.user.role !== 'admin') {
    query.caregiver = req.user._id;
  }

  const profile = await ChildProfile.findOne(query);
  if (!profile) {
    const error = new Error('Profile not found or not accessible.');
    error.statusCode = 404;
    throw error;
  }

  return profile._id;
}

function normalizeResponse(response) {
  return {
    question: response.question && isValidObjectId(response.question) ? response.question : null,
    questionText: String(response.questionText || '').trim(),
    mediaType: String(response.mediaType || '').trim(),
    selectedAnswer: String(response.selectedAnswer || '').trim(),
    correctAnswer: String(response.correctAnswer || '').trim(),
    isCorrect: Boolean(response.isCorrect),
    responseTimeMs: Math.max(0, Number(response.responseTimeMs) || 0)
  };
}

function round(value) {
  if (!Number.isFinite(value)) {
    return 0;
  }
  return Math.round(value * 100) / 100;
}

function buildAttemptFilter(req, baseFilter = {}) {
  const filter = {
    user: req.user._id,
    ...baseFilter
  };

  if (req.query.level) {
    filter.level = Number(req.query.level);
  }

  return filter;
}

async function applyProfileFilter(req, filter) {
  if (req.query.profileId === 'none') {
    filter.profile = null;
    return filter;
  }

  if (req.query.profileId) {
    filter.profile = await ensureProfileAccess(req, req.query.profileId);
  }

  return filter;
}

function summarizeAttempts(attempts) {
  const byLevel = [1, 2, 3].map(level => {
    const levelAttempts = attempts.filter(attempt => attempt.level === level);
    const best = levelAttempts.reduce((bestAttempt, attempt) => {
      if (!bestAttempt || attempt.accuracy > bestAttempt.accuracy) {
        return attempt;
      }
      return bestAttempt;
    }, null);

    const totalAccuracy = levelAttempts.reduce((sum, attempt) => sum + (attempt.accuracy || 0), 0);

    return {
      level,
      attempts: levelAttempts.length,
      bestScore: best ? best.score : 0,
      bestAccuracy: best ? round(best.accuracy) : 0,
      averageAccuracy: levelAttempts.length ? round(totalAccuracy / levelAttempts.length) : 0,
      latestScore: levelAttempts.length ? levelAttempts[0].score : 0,
      latestAccuracy: levelAttempts.length ? round(levelAttempts[0].accuracy) : 0
    };
  });

  const totalAccuracy = attempts.reduce((sum, attempt) => sum + (attempt.accuracy || 0), 0);
  const bestAttempt = attempts.reduce((best, attempt) => {
    if (!best || attempt.accuracy > best.accuracy) {
      return attempt;
    }
    return best;
  }, null);

  return {
    totalAttempts: attempts.length,
    averageAccuracy: attempts.length ? round(totalAccuracy / attempts.length) : 0,
    bestScore: bestAttempt ? bestAttempt.score : 0,
    bestAccuracy: bestAttempt ? round(bestAttempt.accuracy) : 0,
    byLevel,
    recent: attempts.slice(0, 5)
  };
}

router.get('/my', async (req, res) => {
  try {
    const limit = toPositiveInt(req.query.limit, 50, 100);
    const filter = await applyProfileFilter(req, buildAttemptFilter(req));

    const attempts = await GameAttempt.find(filter)
      .sort({ completedAt: -1, createdAt: -1 })
      .limit(limit)
      .populate('profile', 'name nickname')
      .lean();

    res.json(attempts);
  } catch (error) {
    res.status(error.statusCode || 500).json({ message: error.message || 'Unable to load game attempts.' });
  }
});

router.get('/summary', async (req, res) => {
  try {
    const filter = await applyProfileFilter(req, buildAttemptFilter(req));

    const attempts = await GameAttempt.find(filter)
      .sort({ completedAt: -1, createdAt: -1 })
      .limit(1000)
      .populate('profile', 'name nickname')
      .lean();

    res.json(summarizeAttempts(attempts));
  } catch (error) {
    res.status(error.statusCode || 500).json({ message: error.message || 'Unable to load progress summary.' });
  }
});

router.post('/', async (req, res) => {
  try {
    const level = Number(req.body.level);
    const totalQuestions = Number(req.body.totalQuestions);
    const score = Number(req.body.score);
    const responses = Array.isArray(req.body.responses) ? req.body.responses.map(normalizeResponse) : [];
    const correctAnswers = responses.length
      ? responses.filter(response => response.isCorrect).length
      : Number(req.body.correctAnswers) || 0;
    const maxScore = Number(req.body.maxScore) || totalQuestions * 10;
    const startedAt = req.body.startedAt ? new Date(req.body.startedAt) : new Date();
    const completedAt = req.body.completedAt ? new Date(req.body.completedAt) : new Date();
    const profileId = req.body.profile || req.body.childProfile || null;
    const profile = await ensureProfileAccess(req, profileId);

    if (![1, 2, 3].includes(level)) {
      return res.status(400).json({ message: 'Level must be 1, 2, or 3.' });
    }

    if (!Number.isFinite(totalQuestions) || totalQuestions < 1) {
      return res.status(400).json({ message: 'Total questions must be at least 1.' });
    }

    if (!Number.isFinite(score) || score < 0) {
      return res.status(400).json({ message: 'Score is required.' });
    }

    const attempt = await GameAttempt.create({
      user: req.user._id,
      profile,
      level,
      score,
      maxScore,
      totalQuestions,
      correctAnswers,
      accuracy: totalQuestions ? round((correctAnswers / totalQuestions) * 100) : 0,
      startedAt,
      completedAt,
      durationMs: Math.max(0, Number(req.body.durationMs) || completedAt.getTime() - startedAt.getTime()),
      responses
    });

    const savedAttempt = await GameAttempt.findById(attempt._id)
      .populate('profile', 'name nickname')
      .lean();

    res.status(201).json(savedAttempt);
  } catch (error) {
    res.status(error.statusCode || 500).json({ message: error.message || 'Unable to save game attempt.' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    if (!isValidObjectId(req.params.id)) {
      return res.status(400).json({ message: 'Invalid attempt id.' });
    }

    const attempt = await GameAttempt.findOneAndDelete({
      _id: req.params.id,
      user: req.user._id
    });

    if (!attempt) {
      return res.status(404).json({ message: 'Attempt not found.' });
    }

    res.json({ message: 'Attempt deleted.' });
  } catch (error) {
    res.status(500).json({ message: 'Unable to delete attempt.', error: error.message });
  }
});

module.exports = router;
ROUTE

node <<'NODE'
const fs = require('fs');
const path = require('path');
const indexPath = path.join(process.cwd(), 'index.js');
let source = fs.readFileSync(indexPath, 'utf8');

if (!source.includes("/api/game-attempts")) {
  const anchor = "app.use('/api/assessment-sessions', require('./routes/assessmentSessions'));";
  if (source.includes(anchor)) {
    source = source.replace(anchor, `${anchor}\napp.use('/api/game-attempts', require('./routes/gameAttempts'));`);
  } else {
    source = source.replace(
      "app.use('/api/game-questions', require('./routes/gameQuestions'));",
      "app.use('/api/game-attempts', require('./routes/gameAttempts'));\napp.use('/api/game-questions', require('./routes/gameQuestions'));"
    );
  }
  fs.writeFileSync(indexPath, source);
}
NODE

cat > client/src/containers/Level/Level.js <<'LEVEL'
import React, { Component } from 'react';
import axios from 'axios';
import classes from './Level.module.css';
import Questionare from '../../components/Questionaire/Questionare';
import LevelCompleted from '../../components/LevelCompleted/LevelCompleted';
import Loader from '../../components/UI/Loader/Loader';
import { AuthContext } from '../../auth/AuthContext';

class Level extends Component {

    static contextType = AuthContext;

    API_URL = this.props.url;

    state = {
        level: this.props.level,
        questions: [],
        current_question_index: 0,
        score: 0,
        level_completed: false,
        show_answer: false,
        status: 'loading',
        error: '',
        profiles: [],
        profilesRequested: false,
        selectedProfile: '',
        profileLoadError: '',
        startedAt: new Date().toISOString(),
        questionStartedAt: Date.now(),
        responses: [],
        saveStatus: 'idle',
        saveMessage: '',
        attemptSaved: null
    };

    shuffleArray = arr => {
        const cloned = [...arr];
        for (let i = cloned.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [cloned[i], cloned[j]] = [cloned[j], cloned[i]];
        }
        return cloned;
    };

    componentDidMount() {
        this.fetchQuestions();
        this.fetchProfilesIfLoggedIn();
    }

    componentDidUpdate() {
        this.fetchProfilesIfLoggedIn();
    }

    fetchQuestions = () => {
        axios.get(this.API_URL)
            .then(res => res.data)
            .then(data => {
                if (data.length > 0) {
                    const questions = data.map(question => ({
                        ...question,
                        shuffled_answers: this.shuffleArray([question.correct_answer, ...(question.incorrect_answers || [])])
                    }));

                    this.setState({ questions, status: 'ready', error: '' });
                } else {
                    this.setState({ status: 'empty', error: '' });
                }
            })
            .catch(err => {
                const message = err.response && err.response.data && err.response.data.message
                    ? err.response.data.message
                    : 'Unable to load questions. Please try again later.';
                this.setState({ status: 'error', error: message });
            });
    };

    fetchProfilesIfLoggedIn = () => {
        const auth = this.context || {};

        if (!auth.user || this.state.profilesRequested) {
            return;
        }

        this.setState({ profilesRequested: true });

        axios.get('/api/profiles')
            .then(response => {
                this.setState({ profiles: response.data || [], profileLoadError: '' });
            })
            .catch(() => {
                this.setState({ profileLoadError: 'Could not load profiles. The attempt can still be saved to your account.' });
            });
    };

    handleProfileChange = event => {
        this.setState({ selectedProfile: event.target.value });
    };

    handleAnswer = answer => {
        if (this.state.show_answer) {
            return;
        }

        const question = this.state.questions[this.state.current_question_index];
        const isCorrect = answer === question.correct_answer;
        const now = Date.now();

        const response = {
            question: question._id,
            questionText: question.question || '',
            mediaType: question.mediaType || (this.state.level === 1 ? 'image' : this.state.level === 2 ? 'audio' : 'video'),
            selectedAnswer: answer,
            correctAnswer: question.correct_answer,
            isCorrect,
            responseTimeMs: Math.max(0, now - this.state.questionStartedAt)
        };

        this.setState(prevState => ({
            score: prevState.score + (isCorrect ? 10 : 0),
            show_answer: true,
            responses: prevState.responses.concat(response)
        }));
    };

    nextQuestionHandler = () => {
        const isLastQuestion = this.state.current_question_index >= this.state.questions.length - 1;

        if (isLastQuestion) {
            this.setState(prevState => ({
                current_question_index: prevState.current_question_index + 1,
                show_answer: false,
                level_completed: true
            }), this.saveGameAttempt);
            return;
        }

        this.setState(prevState => ({
            current_question_index: prevState.current_question_index + 1,
            show_answer: false,
            questionStartedAt: Date.now()
        }));
    };

    saveGameAttempt = () => {
        const auth = this.context || {};

        if (!auth.user) {
            this.setState({
                saveStatus: 'not-signed-in',
                saveMessage: 'Sign in before playing to save scores and progress history.'
            });
            return;
        }

        if (this.state.saveStatus === 'saving' || this.state.saveStatus === 'saved') {
            return;
        }

        const completedAt = new Date();
        const startedAt = new Date(this.state.startedAt);
        const correctAnswers = this.state.responses.filter(response => response.isCorrect).length;
        const totalQuestions = this.state.questions.length;

        const payload = {
            profile: this.state.selectedProfile || null,
            level: this.state.level,
            score: this.state.score,
            maxScore: totalQuestions * 10,
            totalQuestions,
            correctAnswers,
            startedAt: startedAt.toISOString(),
            completedAt: completedAt.toISOString(),
            durationMs: Math.max(0, completedAt.getTime() - startedAt.getTime()),
            responses: this.state.responses
        };

        this.setState({ saveStatus: 'saving', saveMessage: 'Saving your attempt...' });

        axios.post('/api/game-attempts', payload)
            .then(response => {
                this.setState({
                    saveStatus: 'saved',
                    saveMessage: 'Attempt saved to your progress dashboard.',
                    attemptSaved: response.data
                });
            })
            .catch(error => {
                const message = error.response && error.response.data && error.response.data.message
                    ? error.response.data.message
                    : 'Attempt completed, but it could not be saved right now.';
                this.setState({ saveStatus: 'error', saveMessage: message });
            });
    };

    renderProfileSelector() {
        const auth = this.context || {};

        if (!auth.user) {
            return (
                <div className={classes.AttemptNotice}>
                    Playing as guest. Log in to save your score and progress history.
                </div>
            );
        }

        return (
            <div className={classes.ProfileSelector}>
                <label htmlFor="profile-select">Save attempt under</label>
                <select id="profile-select" value={this.state.selectedProfile} onChange={this.handleProfileChange}>
                    <option value="">My account progress</option>
                    {this.state.profiles.map(profile => (
                        <option key={profile._id} value={profile._id}>
                            {profile.name}{profile.nickname ? ` (${profile.nickname})` : ''}
                        </option>
                    ))}
                </select>
                {this.state.profileLoadError ? <p>{this.state.profileLoadError}</p> : null}
            </div>
        );
    }

    render() {
        if (this.state.level_completed) {
            return (
                <LevelCompleted
                    level={this.state.level}
                    score={this.state.score}
                    questionsLength={this.state.questions.length}
                    saveStatus={this.state.saveStatus}
                    saveMessage={this.state.saveMessage}
                    attemptSaved={this.state.attemptSaved}
                />
            );
        }

        if (this.state.status === 'error') {
            return <div className={classes.MessageBox}>{this.state.error}</div>;
        }

        if (this.state.status === 'empty') {
            return <div className={classes.MessageBox}>No questions are available for this level yet.</div>;
        }

        return (
            this.state.questions.length > 0 ?
                <div className={classes.Container}>
                    {this.renderProfileSelector()}

                    <Questionare
                        score={this.state.score}
                        level={this.state.level}
                        showAnswer={this.state.show_answer}
                        handleAnswer={this.handleAnswer}
                        handleNextQuestion={this.nextQuestionHandler}
                        totalQuestions={this.state.questions.length}
                        questionNo={this.state.current_question_index}
                        question={this.state.questions[this.state.current_question_index]} />
                </div>
                : <div className={classes.LoaderWrapper}>
                    <Loader />
                </div>
        );
    }
}

export default Level;
LEVEL

cat > client/src/containers/Level/Level.module.css <<'CSS'
.Container {
    min-height: calc(100vh - 56px);
    display: flex;
    justify-content: flex-start;
    align-items: center;
    flex-direction: column;
    margin: 0;
    padding: 80px 16px 32px;
    z-index: 300;
}

.LoaderWrapper {
    margin-top: 100px;
    display: flex;
    justify-content: center;
    width: 100%;
}

.ProfileSelector,
.AttemptNotice,
.MessageBox {
    width: min(760px, calc(100% - 24px));
    box-sizing: border-box;
    margin: 0 auto 18px;
    border-radius: 12px;
    background: #ffffff;
    color: #20262f;
    padding: 14px 16px;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.16);
}

.ProfileSelector {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12px;
    flex-wrap: wrap;
}

.ProfileSelector label {
    font-weight: 700;
    color: #144C52;
}

.ProfileSelector select {
    min-width: 220px;
    border: 1px solid #ADD2C9;
    border-radius: 8px;
    padding: 10px 12px;
    font-size: 15px;
}

.ProfileSelector p {
    width: 100%;
    margin: 6px 0 0;
    text-align: center;
    color: #7a4a00;
}

.AttemptNotice {
    text-align: center;
    font-weight: 700;
}

.MessageBox {
    margin-top: 100px;
    text-align: center;
    font-size: 18px;
    line-height: 1.5;
}
CSS

cat > client/src/components/LevelCompleted/LevelCompleted.js <<'COMPLETED'
import React from 'react';
import classes from './LevelCompleted.module.css';
import GoldStar from '../../assets/icons/level-complete/star.svg';
import EmptyStar from '../../assets/icons/level-complete/empty-star.svg';
import Whale from '../../assets/icons/level-complete/whale-animation.svg';
import LevelNoButton from '../UI/Button/LevelNoButton/LevelNoButton';
import { Link } from 'react-router-dom';

const levelCompleted = props => {
    const goldStar = (<img src={GoldStar} alt="Gold Star" />);
    const emptyStar = (<img src={EmptyStar} alt="Empty Star" />);
    const whale = (<img src={Whale} alt="Whale" />);
    const currLevel = '/levels';
    const nextLevel = props.level === 3 ? '/' : `/level${props.level + 1}`;
    const questionsLength = props.questionsLength || 1;
    const maxScore = questionsLength * 10;
    const percentScored = ((props.score / 10) / questionsLength) * 100;

    let saveNotice = null;
    if (props.saveStatus === 'saving') {
        saveNotice = <div className={classes.SaveNotice}>Saving your attempt...</div>;
    } else if (props.saveStatus === 'saved') {
        saveNotice = (
            <div className={classes.SaveNotice}>
                Attempt saved. <Link to="/game-progress">View progress dashboard</Link>
            </div>
        );
    } else if (props.saveStatus === 'not-signed-in') {
        saveNotice = (
            <div className={classes.SaveNotice}>
                {props.saveMessage} <Link to="/login">Log in</Link>
            </div>
        );
    } else if (props.saveStatus === 'error') {
        saveNotice = <div className={classes.SaveNotice}>{props.saveMessage}</div>;
    }

    return (
        <div className={classes.LevelCompleted}>
            <div className={classes.LevelCompleteHeader}>
                Level {props.level} Completed!
            </div>
            <div className={classes.StarsContainer}>
                <div className={classes.Star1}>{percentScored > 0 ? goldStar : emptyStar}</div>
                <div className={classes.Star2}>{percentScored > 30 ? goldStar : emptyStar}</div>
                <div className={classes.Star3}>{percentScored > 60 ? goldStar : emptyStar}</div>
            </div>
            <div className={classes.ScoreContainer}>
                Your Score: {props.score} / {maxScore}
            </div>
            <div className={classes.AccuracyContainer}>
                Accuracy: {Math.round(percentScored)}%
            </div>
            {saveNotice}
            <div className={classes.ButtonsContainer}>
                <Link to={currLevel}>
                    <LevelNoButton url={currLevel}>Replay</LevelNoButton>
                </Link>
                <Link to={nextLevel}>
                    <LevelNoButton url={nextLevel}>Next</LevelNoButton>
                </Link>
            </div>
            <div className={classes.ImageContainer}>
                {whale}
            </div>
        </div>
    );
};

export default levelCompleted;
COMPLETED

cat > client/src/components/LevelCompleted/LevelCompleted.module.css <<'CSS'
.LevelCompleted {
    margin-top: 56px;
}

.LevelCompleteHeader {
    display: flex;
    justify-content: center;
    align-items: center;
    font-size: 60px;
    width: auto;
    color: #000000;
    background-color: #ADD2C9;
    padding: 20px;
}

.StarsContainer, .ButtonsContainer {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 100%;
}

.Star1 img, .Star2 img, .Star3 img {
    height: 100px;
    width: 100px;
    margin: 20px;
    animation: zoomInOut 2s;
}

.ButtonsContainer button {
    margin: 20px 10px 10px 10px;
}

.ImageContainer {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 100%;
}

.ImageContainer img {
    height: 320px;
    width: 375px;
}

.ScoreContainer,
.AccuracyContainer {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 100%;
    font-size: 40px;
}

.AccuracyContainer {
    margin-top: 8px;
    font-size: 24px;
    color: #144C52;
    font-weight: 700;
}

.SaveNotice {
    width: min(720px, calc(100% - 32px));
    margin: 20px auto 0;
    background: #ffffff;
    color: #20262f;
    border-radius: 12px;
    padding: 14px 16px;
    text-align: center;
    font-weight: 700;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.16);
}

.SaveNotice a {
    color: #144C52;
    text-decoration: underline;
}

@keyframes zoomInOut {
    0% {
        transform: scale(1, 1);
    }
    50% {
        transform: scale(1.2, 1.2);
    }
    100% {
        transform: scale(1, 1);
    }
}

@media screen and (max-width: 768px) {
    .LevelCompleteHeader {
        font-size: 55px;
    }
    .Star1 img, .Star2 img, .Star3 img {
        height: 90px;
        width: 90px;
        margin: 10px;
    }
    .ScoreContainer {
        font-size: 35px;
    }
    .ImageContainer img {
        height: 280px;
        width: 320px;
    }
}

@media screen and (max-width: 540px) {
    .LevelCompleteHeader {
        font-size: 65px;
    }
    .Star1 img, .Star2 img, .Star3 img {
        height: 90px;
        width: 90px;
        margin: 10px;
    }
    .ScoreContainer {
        font-size: 35px;
    }
    .ImageContainer img {
        height: 175px;
        width: 320px;
    }
}

@media screen and (max-width: 426px) {
    .LevelCompleteHeader {
        font-size: 55px;
    }
    .Star1 img, .Star2 img, .Star3 img {
        height: 90px;
        width: 90px;
        margin: 10px;
    }
    .ScoreContainer {
        font-size: 35px;
    }
    .ImageContainer img {
        height: 200px;
        width: 320px;
    }
}

@media screen and (max-width: 376px) {
    .LevelCompleteHeader {
        font-size: 45px;
    }
    .Star1 img, .Star2 img, .Star3 img {
        height: 80px;
        width: 80px;
        margin: 10px;
    }
    .ScoreContainer {
        font-size: 35px;
    }
    .ImageContainer img {
        height: 230px;
        width: 320px;
    }
}

@media screen and (max-width: 320px) {
    .LevelCompleteHeader {
        font-size: 45px;
    }
    .Star1 img, .Star2 img, .Star3 img {
        height: 70px;
        width: 70px;
        margin: 10px;
    }
    .ScoreContainer {
        font-size: 35px;
    }
    .ImageContainer img {
        height: 240px;
        width: 320px;
    }
}
CSS

cat > client/src/components/GameProgress/GameProgress.js <<'PROGRESS'
import React, { Component } from 'react';
import axios from 'axios';
import { Link } from 'react-router-dom';
import classes from './GameProgress.module.css';

class GameProgress extends Component {
    state = {
        loading: true,
        error: '',
        summary: null,
        attempts: [],
        profiles: [],
        filters: {
            level: '',
            profileId: ''
        }
    };

    componentDidMount() {
        this.fetchProfiles();
        this.fetchProgress();
    }

    fetchProfiles = () => {
        axios.get('/api/profiles')
            .then(response => {
                this.setState({ profiles: response.data || [] });
            })
            .catch(() => {
                this.setState({ profiles: [] });
            });
    };

    fetchProgress = () => {
        const params = {};
        if (this.state.filters.level) {
            params.level = this.state.filters.level;
        }
        if (this.state.filters.profileId) {
            params.profileId = this.state.filters.profileId;
        }

        this.setState({ loading: true, error: '' });

        Promise.all([
            axios.get('/api/game-attempts/summary', { params }),
            axios.get('/api/game-attempts/my', { params: { ...params, limit: 50 } })
        ])
            .then(([summaryResponse, attemptsResponse]) => {
                this.setState({
                    summary: summaryResponse.data,
                    attempts: attemptsResponse.data || [],
                    loading: false,
                    error: ''
                });
            })
            .catch(error => {
                const message = error.response && error.response.data && error.response.data.message
                    ? error.response.data.message
                    : 'Unable to load game progress.';
                this.setState({ loading: false, error: message });
            });
    };

    handleFilterChange = event => {
        const { name, value } = event.target;
        this.setState(prevState => ({
            filters: {
                ...prevState.filters,
                [name]: value
            }
        }), this.fetchProgress);
    };

    formatDate(date) {
        if (!date) {
            return 'Not available';
        }
        return new Date(date).toLocaleString();
    }

    formatDuration(durationMs) {
        const seconds = Math.round((Number(durationMs) || 0) / 1000);
        if (seconds < 60) {
            return `${seconds}s`;
        }
        const minutes = Math.floor(seconds / 60);
        const remainingSeconds = seconds % 60;
        return `${minutes}m ${remainingSeconds}s`;
    }

    renderSummary() {
        const summary = this.state.summary;

        if (!summary) {
            return null;
        }

        return (
            <section className={classes.SummaryGrid}>
                <div className={classes.SummaryCard}>
                    <span>Total attempts</span>
                    <strong>{summary.totalAttempts}</strong>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Average accuracy</span>
                    <strong>{summary.averageAccuracy}%</strong>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Best accuracy</span>
                    <strong>{summary.bestAccuracy}%</strong>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Best score</span>
                    <strong>{summary.bestScore}</strong>
                </div>
            </section>
        );
    }

    renderLevelBreakdown() {
        const summary = this.state.summary;

        if (!summary || !summary.byLevel) {
            return null;
        }

        return (
            <section className={classes.Panel}>
                <h2>Level breakdown</h2>
                <div className={classes.LevelRows}>
                    {summary.byLevel.map(level => (
                        <div className={classes.LevelRow} key={level.level}>
                            <div className={classes.LevelTitle}>Level {level.level}</div>
                            <div className={classes.BarTrack}>
                                <div className={classes.BarFill} style={{ width: `${Math.min(level.averageAccuracy, 100)}%` }}></div>
                            </div>
                            <div className={classes.LevelStats}>
                                {level.attempts} attempts · Avg {level.averageAccuracy}% · Best {level.bestAccuracy}%
                            </div>
                        </div>
                    ))}
                </div>
            </section>
        );
    }

    renderAttempts() {
        if (!this.state.attempts.length) {
            return (
                <section className={classes.EmptyState}>
                    <h2>No game attempts saved yet</h2>
                    <p>Play an emotion game while logged in. Your score, accuracy, and response history will appear here.</p>
                    <Link to="/levels">Open games</Link>
                </section>
            );
        }

        return (
            <section className={classes.Panel}>
                <h2>Recent attempts</h2>
                <div className={classes.AttemptList}>
                    {this.state.attempts.map(attempt => (
                        <article className={classes.AttemptCard} key={attempt._id}>
                            <div>
                                <h3>Level {attempt.level}</h3>
                                <p>
                                    {attempt.profile ? `Profile: ${attempt.profile.name}` : 'Saved to account progress'}
                                </p>
                            </div>
                            <div className={classes.AttemptStats}>
                                <span>{attempt.score} / {attempt.maxScore}</span>
                                <strong>{Math.round(attempt.accuracy)}%</strong>
                            </div>
                            <div className={classes.AttemptMeta}>
                                <span>{this.formatDate(attempt.completedAt)}</span>
                                <span>{this.formatDuration(attempt.durationMs)}</span>
                                <span>{attempt.correctAnswers} of {attempt.totalQuestions} correct</span>
                            </div>
                        </article>
                    ))}
                </div>
            </section>
        );
    }

    render() {
        return (
            <div className={classes.Page}>
                <section className={classes.Header}>
                    <div>
                        <h1>Game Progress</h1>
                        <p>Track saved emotion-learning game attempts by level and child profile.</p>
                    </div>
                    <Link to="/levels">Play games</Link>
                </section>

                <section className={classes.Filters}>
                    <label>
                        Level
                        <select name="level" value={this.state.filters.level} onChange={this.handleFilterChange}>
                            <option value="">All levels</option>
                            <option value="1">Level 1: Images</option>
                            <option value="2">Level 2: Audio</option>
                            <option value="3">Level 3: Video</option>
                        </select>
                    </label>
                    <label>
                        Profile
                        <select name="profileId" value={this.state.filters.profileId} onChange={this.handleFilterChange}>
                            <option value="">All saved attempts</option>
                            <option value="none">Account-only attempts</option>
                            {this.state.profiles.map(profile => (
                                <option key={profile._id} value={profile._id}>{profile.name}</option>
                            ))}
                        </select>
                    </label>
                </section>

                {this.state.loading ? <div className={classes.Panel}>Loading progress...</div> : null}
                {this.state.error ? <div className={classes.ErrorBox}>{this.state.error}</div> : null}

                {!this.state.loading && !this.state.error ? this.renderSummary() : null}
                {!this.state.loading && !this.state.error ? this.renderLevelBreakdown() : null}
                {!this.state.loading && !this.state.error ? this.renderAttempts() : null}
            </div>
        );
    }
}

export default GameProgress;
PROGRESS

cat > client/src/components/GameProgress/GameProgress.module.css <<'CSS'
.Page {
    min-height: calc(100vh - 56px);
    padding: 96px 32px 48px;
    background: #20262f;
    color: #ffffff;
}

.Header {
    max-width: 1080px;
    margin: 0 auto 24px;
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 16px;
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

.Header a,
.EmptyState a {
    display: inline-block;
    border-radius: 8px;
    background: #ADD2C9;
    color: #20262f;
    text-decoration: none;
    font-weight: 800;
    padding: 11px 16px;
}

.Filters {
    max-width: 1080px;
    margin: 0 auto 18px;
    display: flex;
    gap: 16px;
    flex-wrap: wrap;
    background: #ffffff;
    color: #20262f;
    border-radius: 12px;
    padding: 16px;
}

.Filters label {
    display: flex;
    flex-direction: column;
    gap: 6px;
    font-weight: 800;
    color: #144C52;
}

.Filters select {
    min-width: 220px;
    border: 1px solid #ADD2C9;
    border-radius: 8px;
    padding: 10px 12px;
    font-size: 15px;
}

.SummaryGrid {
    max-width: 1080px;
    margin: 0 auto 18px;
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
    gap: 16px;
}

.SummaryCard,
.Panel,
.EmptyState,
.ErrorBox {
    background: #ffffff;
    color: #20262f;
    border-radius: 12px;
    padding: 20px;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.22);
}

.SummaryCard span {
    display: block;
    color: #4c5965;
    margin-bottom: 8px;
}

.SummaryCard strong {
    display: block;
    color: #144C52;
    font-size: 34px;
}

.Panel,
.EmptyState,
.ErrorBox {
    max-width: 1080px;
    margin: 0 auto 18px;
}

.Panel h2,
.EmptyState h2 {
    margin: 0 0 14px;
    color: #144C52;
}

.LevelRows {
    display: flex;
    flex-direction: column;
    gap: 16px;
}

.LevelRow {
    display: grid;
    grid-template-columns: 90px 1fr 260px;
    gap: 14px;
    align-items: center;
}

.LevelTitle {
    font-weight: 800;
    color: #144C52;
}

.BarTrack {
    height: 14px;
    border-radius: 999px;
    background: #e6eeee;
    overflow: hidden;
}

.BarFill {
    height: 100%;
    border-radius: 999px;
    background: #144C52;
    transition: width 0.3s ease;
}

.LevelStats {
    color: #4c5965;
    font-size: 14px;
}

.AttemptList {
    display: flex;
    flex-direction: column;
    gap: 14px;
}

.AttemptCard {
    display: grid;
    grid-template-columns: 1fr 140px;
    gap: 12px;
    border: 1px solid #e1eeee;
    border-radius: 12px;
    padding: 16px;
}

.AttemptCard h3 {
    margin: 0 0 6px;
    color: #144C52;
}

.AttemptCard p {
    margin: 0;
    color: #4c5965;
}

.AttemptStats {
    text-align: right;
}

.AttemptStats span,
.AttemptStats strong {
    display: block;
}

.AttemptStats strong {
    margin-top: 6px;
    color: #144C52;
    font-size: 28px;
}

.AttemptMeta {
    grid-column: 1 / -1;
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    color: #4c5965;
    font-size: 14px;
}

.EmptyState p {
    color: #4c5965;
    line-height: 1.5;
}

.ErrorBox {
    border-left: 5px solid #f00946;
}

@media (max-width: 760px) {
    .Page {
        padding: 84px 16px 32px;
    }

    .Header {
        flex-direction: column;
    }

    .LevelRow,
    .AttemptCard {
        grid-template-columns: 1fr;
    }

    .AttemptStats {
        text-align: left;
    }
}
CSS

node <<'NODE'
const fs = require('fs');
const path = require('path');

function updateFile(filePath, updater) {
  const fullPath = path.join(process.cwd(), filePath);
  let source = fs.readFileSync(fullPath, 'utf8');
  const updated = updater(source);
  if (updated !== source) {
    fs.writeFileSync(fullPath, updated);
  }
}

updateFile('client/src/App.js', source => {
  if (!source.includes("components/GameProgress/GameProgress")) {
    source = source.replace(
      "import Screening from './components/Screening/Screening';",
      "import Screening from './components/Screening/Screening';\nimport GameProgress from './components/GameProgress/GameProgress';"
    );
  }

  if (!source.includes('path="/game-progress"')) {
    source = source.replace(
      '<ProtectedRoute path="/screening/new" exact component={Screening} />',
      '<ProtectedRoute path="/screening/new" exact component={Screening} />\n                <ProtectedRoute path="/game-progress" exact component={GameProgress} />'
    );
  }

  return source;
});

updateFile('client/src/components/Dashboard/Dashboard.js', source => {
  if (source.includes('View game progress')) {
    return source;
  }

  const card = `
                    <div className={classes.Card}>
                        <h2>Game progress</h2>
                        <p>Review saved emotion-game attempts, accuracy trends, and recent practice history.</p>
                        <Link to="/game-progress">View game progress</Link>
                    </div>
`;

  return source.replace(
    `                    <div className={classes.Card}>
                        <h2>Screening support</h2>`,
    `${card}
                    <div className={classes.Card}>
                        <h2>Screening support</h2>`
  );
});

updateFile('client/src/components/Navigation/NavigationItems/NavigationItems.js', source => {
  if (source.includes('link="/game-progress"')) {
    return source;
  }

  return source.replace(
    `{auth.user ? <NavigationItem link="/profiles">Profiles</NavigationItem> : null}`,
    `{auth.user ? <NavigationItem link="/profiles">Profiles</NavigationItem> : null}\n                    {auth.user ? <NavigationItem link="/game-progress">Progress</NavigationItem> : null}`
  );
});

updateFile('client/src/components/Navigation/SideDrawer/SideDrawer.js', source => {
  if (source.includes('link="/game-progress"')) {
    return source;
  }

  return source.replace(
    `{auth.user ? <NavigationItem link="/profiles">Profiles</NavigationItem> : null}`,
    `{auth.user ? <NavigationItem link="/profiles">Profiles</NavigationItem> : null}\n                        {auth.user ? <NavigationItem link="/game-progress">Progress</NavigationItem> : null}`
  );
});
NODE

mkdir -p docs
cat > docs/GAME_PROGRESS_NOTES.md <<'DOC'
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
DOC

echo "Phase 3 applied successfully. Restart the app and test /game-progress after playing one level while logged in."
