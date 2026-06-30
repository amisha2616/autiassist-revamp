#!/usr/bin/env bash
set -euo pipefail

if [ ! -f "package.json" ] || [ ! -d "client/src" ]; then
  echo "Run this script from the autismo-revamp-starter project root."
  exit 1
fi

if [ ! -f "middleware/auth.js" ] || [ ! -f "models/childProfile.js" ]; then
  echo "Auth and profile upgrades are required before this step. Apply earlier phases first."
  exit 1
fi

if [ ! -f "models/gameAttempt.js" ]; then
  echo "Game progress upgrade is required before this step. Apply apply_game_progress_upgrade.sh first."
  exit 1
fi

echo "Applying Phase 4: wellbeing tracker and caregiver notes..."

mkdir -p models routes client/src/components/Wellbeing docs

cat > models/wellbeingLog.js <<'MODEL'
const mongoose = require('mongoose');

const wellbeingLogSchema = new mongoose.Schema(
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
      required: true,
      index: true
    },
    logDate: {
      type: Date,
      required: true,
      default: Date.now,
      index: true
    },
    sleepQuality: {
      type: Number,
      min: 1,
      max: 5,
      required: true
    },
    sensoryOverload: {
      type: Number,
      min: 1,
      max: 5,
      required: true
    },
    communicationEase: {
      type: Number,
      min: 1,
      max: 5,
      required: true
    },
    socialInteraction: {
      type: Number,
      min: 1,
      max: 5,
      required: true
    },
    mood: {
      type: String,
      enum: ['calm', 'happy', 'tired', 'anxious', 'frustrated', 'overwhelmed', 'mixed'],
      default: 'mixed',
      index: true
    },
    distressEpisodes: {
      type: Number,
      min: 0,
      max: 20,
      default: 0
    },
    triggers: {
      type: [String],
      default: []
    },
    strategies: {
      type: [String],
      default: []
    },
    notes: {
      type: String,
      trim: true,
      maxlength: 2000,
      default: ''
    },
    overallScore: {
      type: Number,
      min: 0,
      max: 100,
      default: 0,
      index: true
    }
  },
  { timestamps: true }
);

function clampNumber(value, min, max) {
  const number = Number(value);
  if (!Number.isFinite(number)) {
    return min;
  }
  return Math.max(min, Math.min(max, number));
}

wellbeingLogSchema.pre('validate', function calculateOverallScore(next) {
  const sleep = clampNumber(this.sleepQuality, 1, 5);
  const sensory = 6 - clampNumber(this.sensoryOverload, 1, 5);
  const communication = clampNumber(this.communicationEase, 1, 5);
  const social = clampNumber(this.socialInteraction, 1, 5);
  const distress = Math.max(0, 5 - Math.min(clampNumber(this.distressEpisodes, 0, 20), 5));

  const rawAverage = (sleep + sensory + communication + social + distress) / 5;
  this.overallScore = Math.round((rawAverage / 5) * 100);
  next();
});

module.exports = mongoose.model('WellbeingLog', wellbeingLogSchema);
MODEL

cat > routes/wellbeingLogs.js <<'ROUTE'
const router = require('express').Router();
const mongoose = require('mongoose');
const WellbeingLog = require('../models/wellbeingLog');
const ChildProfile = require('../models/childProfile');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(String(id));
}

function ownerQuery(req, extra) {
  if (req.user.role === 'admin') {
    return { ...extra };
  }
  return { caregiver: req.user._id, ...extra };
}

function logOwnerFilter(req, extra) {
  if (req.user.role === 'admin') {
    return { ...extra };
  }
  return { user: req.user._id, ...extra };
}

async function ensureProfileAccess(req, profileId) {
  if (!profileId || !isValidObjectId(profileId)) {
    const error = new Error('A valid child profile is required.');
    error.statusCode = 400;
    throw error;
  }

  const profile = await ChildProfile.findOne(ownerQuery(req, { _id: profileId, archived: false }));
  if (!profile) {
    const error = new Error('Profile not found or not accessible.');
    error.statusCode = 404;
    throw error;
  }

  return profile;
}

function toScore(value, fallback) {
  const number = Number(value);
  if (!Number.isFinite(number)) {
    return fallback;
  }
  return Math.max(1, Math.min(5, Math.round(number)));
}

function toDistressEpisodes(value) {
  const number = Number(value);
  if (!Number.isFinite(number) || number < 0) {
    return 0;
  }
  return Math.max(0, Math.min(20, Math.round(number)));
}

function splitList(value) {
  if (Array.isArray(value)) {
    return value.map(item => String(item || '').trim()).filter(Boolean).slice(0, 12);
  }

  return String(value || '')
    .split(',')
    .map(item => item.trim())
    .filter(Boolean)
    .slice(0, 12);
}

function parseLogDate(value) {
  if (!value) {
    return new Date();
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    const error = new Error('Use a valid log date.');
    error.statusCode = 400;
    throw error;
  }
  return date;
}

function toPositiveInt(value, fallback, max) {
  const number = Number(value);
  if (!Number.isFinite(number) || number <= 0) {
    return fallback;
  }
  return Math.min(Math.floor(number), max);
}

function round(value) {
  if (!Number.isFinite(value)) {
    return 0;
  }
  return Math.round(value * 100) / 100;
}

function mostCommonMood(logs) {
  const counts = {};
  logs.forEach(log => {
    counts[log.mood] = (counts[log.mood] || 0) + 1;
  });

  let bestMood = 'Not enough data';
  let bestCount = 0;
  Object.keys(counts).forEach(mood => {
    if (counts[mood] > bestCount) {
      bestMood = mood;
      bestCount = counts[mood];
    }
  });

  return bestMood;
}

function buildFilter(req, query) {
  const filter = logOwnerFilter(req, {});

  if (query.profileId) {
    if (!isValidObjectId(query.profileId)) {
      const error = new Error('Invalid profile id.');
      error.statusCode = 400;
      throw error;
    }
    filter.profile = query.profileId;
  }

  return filter;
}

router.get('/my', async (req, res) => {
  try {
    const filter = buildFilter(req, req.query);
    const limit = toPositiveInt(req.query.limit, 60, 200);

    const logs = await WellbeingLog.find(filter)
      .populate('profile', 'name nickname')
      .sort({ logDate: -1, createdAt: -1 })
      .limit(limit)
      .lean();

    res.json(logs);
  } catch (error) {
    res.status(error.statusCode || 500).json({ message: error.message || 'Unable to load wellbeing logs.' });
  }
});

router.get('/summary', async (req, res) => {
  try {
    const filter = buildFilter(req, req.query);
    const limit = toPositiveInt(req.query.limit, 90, 365);

    const logs = await WellbeingLog.find(filter)
      .populate('profile', 'name nickname')
      .sort({ logDate: -1, createdAt: -1 })
      .limit(limit)
      .lean();

    const count = logs.length;
    const averageOverallScore = count
      ? round(logs.reduce((sum, log) => sum + Number(log.overallScore || 0), 0) / count)
      : 0;
    const averageSleepQuality = count
      ? round(logs.reduce((sum, log) => sum + Number(log.sleepQuality || 0), 0) / count)
      : 0;
    const averageSensoryOverload = count
      ? round(logs.reduce((sum, log) => sum + Number(log.sensoryOverload || 0), 0) / count)
      : 0;
    const averageCommunicationEase = count
      ? round(logs.reduce((sum, log) => sum + Number(log.communicationEase || 0), 0) / count)
      : 0;
    const averageDistressEpisodes = count
      ? round(logs.reduce((sum, log) => sum + Number(log.distressEpisodes || 0), 0) / count)
      : 0;

    const trend = logs
      .slice()
      .reverse()
      .map(log => ({
        id: log._id,
        logDate: log.logDate,
        profile: log.profile,
        mood: log.mood,
        overallScore: log.overallScore,
        sensoryOverload: log.sensoryOverload,
        distressEpisodes: log.distressEpisodes
      }));

    res.json({
      totalLogs: count,
      averageOverallScore,
      averageSleepQuality,
      averageSensoryOverload,
      averageCommunicationEase,
      averageDistressEpisodes,
      mostCommonMood: mostCommonMood(logs),
      recent: logs.slice(0, 8),
      trend
    });
  } catch (error) {
    res.status(error.statusCode || 500).json({ message: error.message || 'Unable to load wellbeing summary.' });
  }
});

router.post('/', async (req, res) => {
  try {
    const profile = await ensureProfileAccess(req, req.body.profileId);
    const notes = String(req.body.notes || '').trim();

    const log = await WellbeingLog.create({
      user: req.user._id,
      profile: profile._id,
      logDate: parseLogDate(req.body.logDate),
      sleepQuality: toScore(req.body.sleepQuality, 3),
      sensoryOverload: toScore(req.body.sensoryOverload, 3),
      communicationEase: toScore(req.body.communicationEase, 3),
      socialInteraction: toScore(req.body.socialInteraction, 3),
      mood: String(req.body.mood || 'mixed').trim() || 'mixed',
      distressEpisodes: toDistressEpisodes(req.body.distressEpisodes),
      triggers: splitList(req.body.triggers),
      strategies: splitList(req.body.strategies),
      notes
    });

    const populatedLog = await WellbeingLog.findById(log._id)
      .populate('profile', 'name nickname')
      .lean();

    res.status(201).json(populatedLog);
  } catch (error) {
    res.status(error.statusCode || 500).json({ message: error.message || 'Unable to save wellbeing log.' });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    if (!isValidObjectId(req.params.id)) {
      return res.status(400).json({ message: 'Invalid wellbeing log id.' });
    }

    const deletedLog = await WellbeingLog.findOneAndDelete(logOwnerFilter(req, { _id: req.params.id }));
    if (!deletedLog) {
      return res.status(404).json({ message: 'Wellbeing log not found.' });
    }

    res.json({ message: 'Wellbeing log deleted.' });
  } catch (error) {
    res.status(500).json({ message: 'Unable to delete wellbeing log.', error: error.message });
  }
});

module.exports = router;
ROUTE

cat > client/src/components/Wellbeing/Wellbeing.js <<'COMPONENT'
import React, { Component } from 'react';
import axios from 'axios';
import { Link } from 'react-router-dom';
import classes from './Wellbeing.module.css';

const today = () => new Date().toISOString().slice(0, 10);

class Wellbeing extends Component {
    state = {
        profiles: [],
        logs: [],
        summary: null,
        loading: true,
        submitting: false,
        error: '',
        success: '',
        filters: {
            profileId: ''
        },
        form: {
            profileId: '',
            logDate: today(),
            sleepQuality: '3',
            sensoryOverload: '3',
            communicationEase: '3',
            socialInteraction: '3',
            mood: 'mixed',
            distressEpisodes: '0',
            triggers: '',
            strategies: '',
            notes: ''
        }
    };

    componentDidMount() {
        this.loadInitialData();
    }

    loadInitialData = async () => {
        this.setState({ loading: true, error: '' });

        try {
            const profilesResponse = await axios.get('/api/profiles');
            const profiles = profilesResponse.data || [];
            const firstProfileId = profiles.length ? profiles[0]._id : '';

            this.setState(prevState => ({
                profiles,
                filters: {
                    ...prevState.filters,
                    profileId: firstProfileId
                },
                form: {
                    ...prevState.form,
                    profileId: firstProfileId
                }
            }), this.loadWellbeingData);
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to load profiles.';
            this.setState({ loading: false, error: message });
        }
    };

    loadWellbeingData = async () => {
        const params = {};
        if (this.state.filters.profileId) {
            params.profileId = this.state.filters.profileId;
        }

        this.setState({ loading: true, error: '' });

        try {
            const responses = await Promise.all([
                axios.get('/api/wellbeing-logs/summary', { params }),
                axios.get('/api/wellbeing-logs/my', { params: { ...params, limit: 80 } })
            ]);

            this.setState({
                summary: responses[0].data,
                logs: responses[1].data || [],
                loading: false,
                error: ''
            });
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to load wellbeing logs.';
            this.setState({ loading: false, error: message });
        }
    };

    handleFormChange = event => {
        const { name, value } = event.target;
        this.setState(prevState => ({
            form: {
                ...prevState.form,
                [name]: value
            },
            error: '',
            success: ''
        }));
    };

    handleFilterChange = event => {
        const { value } = event.target;
        this.setState(prevState => ({
            filters: {
                ...prevState.filters,
                profileId: value
            },
            form: {
                ...prevState.form,
                profileId: value || prevState.form.profileId
            }
        }), this.loadWellbeingData);
    };

    submitHandler = async event => {
        event.preventDefault();

        if (!this.state.form.profileId) {
            this.setState({ error: 'Create and select a child profile before saving a wellbeing log.' });
            return;
        }

        this.setState({ submitting: true, error: '', success: '' });

        try {
            await axios.post('/api/wellbeing-logs', this.state.form);
            this.setState(prevState => ({
                submitting: false,
                success: 'Wellbeing log saved.',
                form: {
                    ...prevState.form,
                    logDate: today(),
                    sleepQuality: '3',
                    sensoryOverload: '3',
                    communicationEase: '3',
                    socialInteraction: '3',
                    mood: 'mixed',
                    distressEpisodes: '0',
                    triggers: '',
                    strategies: '',
                    notes: ''
                }
            }), this.loadWellbeingData);
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to save wellbeing log.';
            this.setState({ submitting: false, error: message });
        }
    };

    deleteLog = async logId => {
        const confirmed = window.confirm('Delete this wellbeing log?');
        if (!confirmed) {
            return;
        }

        try {
            await axios.delete(`/api/wellbeing-logs/${logId}`);
            this.loadWellbeingData();
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to delete wellbeing log.';
            this.setState({ error: message });
        }
    };

    formatDate(date) {
        if (!date) {
            return 'Not available';
        }
        return new Date(date).toLocaleDateString();
    }

    formatMood(mood) {
        return String(mood || 'mixed').replace(/_/g, ' ');
    }

    renderScoreLabel(value) {
        const score = Number(value);
        if (score >= 80) {
            return 'Stable';
        }
        if (score >= 60) {
            return 'Moderate';
        }
        if (score > 0) {
            return 'Needs attention';
        }
        return 'No data';
    }

    renderSummary() {
        const summary = this.state.summary;
        if (!summary) {
            return null;
        }

        return (
            <section className={classes.SummaryGrid}>
                <div className={classes.SummaryCard}>
                    <span>Total logs</span>
                    <strong>{summary.totalLogs}</strong>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Average wellbeing</span>
                    <strong>{summary.averageOverallScore}%</strong>
                    <small>{this.renderScoreLabel(summary.averageOverallScore)}</small>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Common mood</span>
                    <strong>{this.formatMood(summary.mostCommonMood)}</strong>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Avg sensory overload</span>
                    <strong>{summary.averageSensoryOverload}/5</strong>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Avg communication ease</span>
                    <strong>{summary.averageCommunicationEase}/5</strong>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Avg distress episodes</span>
                    <strong>{summary.averageDistressEpisodes}</strong>
                </div>
            </section>
        );
    }

    renderTrend() {
        const summary = this.state.summary;
        const trend = summary && summary.trend ? summary.trend.slice(-14) : [];

        if (!trend.length) {
            return null;
        }

        return (
            <section className={classes.Panel}>
                <h2>Recent wellbeing trend</h2>
                <p className={classes.HelperText}>Higher bars mean a more settled day based on sleep, sensory load, communication, social interaction, and distress frequency.</p>
                <div className={classes.TrendList}>
                    {trend.map(item => (
                        <div className={classes.TrendRow} key={item.id}>
                            <span>{this.formatDate(item.logDate)}</span>
                            <div className={classes.BarTrack}>
                                <div className={classes.BarFill} style={{ width: `${Math.max(4, Math.min(Number(item.overallScore) || 0, 100))}%` }}></div>
                            </div>
                            <strong>{item.overallScore}%</strong>
                        </div>
                    ))}
                </div>
            </section>
        );
    }

    renderForm() {
        return (
            <form className={classes.Card} onSubmit={this.submitHandler}>
                <h2>Add daily log</h2>
                <p className={classes.HelperText}>Use this to record patterns. It is for caregiver tracking, not diagnosis.</p>

                {this.state.error ? <div className={classes.Error}>{this.state.error}</div> : null}
                {this.state.success ? <div className={classes.Success}>{this.state.success}</div> : null}

                <label>Child profile</label>
                <select name="profileId" value={this.state.form.profileId} onChange={this.handleFormChange} required>
                    <option value="">Select profile</option>
                    {this.state.profiles.map(profile => (
                        <option key={profile._id} value={profile._id}>{profile.name}</option>
                    ))}
                </select>

                <label>Date</label>
                <input name="logDate" type="date" value={this.state.form.logDate} onChange={this.handleFormChange} required />

                <label>Sleep quality</label>
                <select name="sleepQuality" value={this.state.form.sleepQuality} onChange={this.handleFormChange}>
                    <option value="1">1 - Very poor</option>
                    <option value="2">2 - Poor</option>
                    <option value="3">3 - Average</option>
                    <option value="4">4 - Good</option>
                    <option value="5">5 - Very good</option>
                </select>

                <label>Sensory overload</label>
                <select name="sensoryOverload" value={this.state.form.sensoryOverload} onChange={this.handleFormChange}>
                    <option value="1">1 - Very low</option>
                    <option value="2">2 - Low</option>
                    <option value="3">3 - Moderate</option>
                    <option value="4">4 - High</option>
                    <option value="5">5 - Very high</option>
                </select>

                <label>Communication ease</label>
                <select name="communicationEase" value={this.state.form.communicationEase} onChange={this.handleFormChange}>
                    <option value="1">1 - Very difficult</option>
                    <option value="2">2 - Difficult</option>
                    <option value="3">3 - Mixed</option>
                    <option value="4">4 - Good</option>
                    <option value="5">5 - Very good</option>
                </select>

                <label>Social interaction</label>
                <select name="socialInteraction" value={this.state.form.socialInteraction} onChange={this.handleFormChange}>
                    <option value="1">1 - Avoidant or distressed</option>
                    <option value="2">2 - Limited</option>
                    <option value="3">3 - Mixed</option>
                    <option value="4">4 - Engaged</option>
                    <option value="5">5 - Very engaged</option>
                </select>

                <label>Mood</label>
                <select name="mood" value={this.state.form.mood} onChange={this.handleFormChange}>
                    <option value="calm">Calm</option>
                    <option value="happy">Happy</option>
                    <option value="tired">Tired</option>
                    <option value="anxious">Anxious</option>
                    <option value="frustrated">Frustrated</option>
                    <option value="overwhelmed">Overwhelmed</option>
                    <option value="mixed">Mixed</option>
                </select>

                <label>Distress episodes</label>
                <input name="distressEpisodes" type="number" min="0" max="20" value={this.state.form.distressEpisodes} onChange={this.handleFormChange} />

                <label>Possible triggers</label>
                <input name="triggers" value={this.state.form.triggers} onChange={this.handleFormChange} placeholder="Example: loud noise, crowd, routine change" />

                <label>Helpful strategies</label>
                <input name="strategies" value={this.state.form.strategies} onChange={this.handleFormChange} placeholder="Example: quiet space, visual schedule, deep pressure" />

                <label>Notes</label>
                <textarea name="notes" rows="4" value={this.state.form.notes} onChange={this.handleFormChange} placeholder="Short caregiver note for this day." />

                <button type="submit" disabled={this.state.submitting || !this.state.profiles.length}>
                    {this.state.submitting ? 'Saving...' : 'Save wellbeing log'}
                </button>
            </form>
        );
    }

    renderLogs() {
        if (this.state.loading) {
            return <section className={classes.Panel}>Loading wellbeing logs...</section>;
        }

        if (!this.state.logs.length) {
            return (
                <section className={classes.EmptyState}>
                    <h2>No wellbeing logs yet</h2>
                    <p>Add a daily log to start building a useful progress history.</p>
                </section>
            );
        }

        return (
            <section className={classes.Panel}>
                <h2>Recent logs</h2>
                <div className={classes.LogList}>
                    {this.state.logs.map(log => (
                        <article className={classes.LogCard} key={log._id}>
                            <div className={classes.LogTop}>
                                <div>
                                    <h3>{log.profile && log.profile.name ? log.profile.name : 'Profile'}</h3>
                                    <p>{this.formatDate(log.logDate)} · Mood: {this.formatMood(log.mood)}</p>
                                </div>
                                <div className={classes.ScorePill}>{log.overallScore}%</div>
                            </div>
                            <div className={classes.MetricGrid}>
                                <span>Sleep {log.sleepQuality}/5</span>
                                <span>Sensory {log.sensoryOverload}/5</span>
                                <span>Communication {log.communicationEase}/5</span>
                                <span>Social {log.socialInteraction}/5</span>
                                <span>Distress {log.distressEpisodes}</span>
                            </div>
                            {log.triggers && log.triggers.length ? <p><strong>Triggers:</strong> {log.triggers.join(', ')}</p> : null}
                            {log.strategies && log.strategies.length ? <p><strong>Strategies:</strong> {log.strategies.join(', ')}</p> : null}
                            {log.notes ? <p className={classes.Notes}>{log.notes}</p> : null}
                            <button type="button" className={classes.DeleteButton} onClick={() => this.deleteLog(log._id)}>Delete</button>
                        </article>
                    ))}
                </div>
            </section>
        );
    }

    render() {
        const hasProfiles = this.state.profiles.length > 0;

        return (
            <div className={classes.Page}>
                <section className={classes.Header}>
                    <div>
                        <h1>Wellbeing Tracker</h1>
                        <p>Save caregiver notes about sleep, sensory load, communication, mood, and daily supports.</p>
                    </div>
                    <Link to="/profiles">Manage profiles</Link>
                </section>

                {!hasProfiles && !this.state.loading ? (
                    <section className={classes.EmptyState}>
                        <h2>Create a child profile first</h2>
                        <p>Wellbeing logs are linked to child profiles so they can be reviewed with screening and game progress later.</p>
                        <Link to="/profiles">Add profile</Link>
                    </section>
                ) : null}

                {hasProfiles ? (
                    <section className={classes.Filters}>
                        <label>
                            View logs for
                            <select value={this.state.filters.profileId} onChange={this.handleFilterChange}>
                                <option value="">All profiles</option>
                                {this.state.profiles.map(profile => (
                                    <option key={profile._id} value={profile._id}>{profile.name}</option>
                                ))}
                            </select>
                        </label>
                    </section>
                ) : null}

                {hasProfiles ? this.renderSummary() : null}

                <section className={classes.Layout}>
                    {this.renderForm()}
                    <div>
                        {hasProfiles ? this.renderTrend() : null}
                        {hasProfiles ? this.renderLogs() : null}
                    </div>
                </section>
            </div>
        );
    }
}

export default Wellbeing;
COMPONENT

cat > client/src/components/Wellbeing/Wellbeing.module.css <<'CSS'
.Page {
    min-height: calc(100vh - 56px);
    padding: 96px 32px 48px;
    background: #20262f;
    color: #ffffff;
}

.Header {
    max-width: 1100px;
    margin: 0 auto 24px;
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 18px;
}

.Header h1 {
    margin: 0 0 8px;
    font-size: 36px;
}

.Header p,
.HelperText {
    margin: 0;
    color: #d6e4e2;
    line-height: 1.5;
}

.Header a,
.EmptyState a,
.Card button {
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

.Layout {
    max-width: 1100px;
    margin: 0 auto;
    display: grid;
    grid-template-columns: 360px 1fr;
    gap: 18px;
    align-items: start;
}

.Card,
.Panel,
.EmptyState,
.Filters {
    background: #ffffff;
    color: #20262f;
    border-radius: 12px;
    padding: 22px;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.22);
}

.Card h2,
.Panel h2,
.EmptyState h2 {
    margin: 0 0 10px;
    color: #144C52;
}

.Card .HelperText,
.Panel .HelperText {
    color: #4c5965;
    margin-bottom: 16px;
}

.Card label,
.Filters label {
    display: block;
    margin-top: 14px;
    margin-bottom: 6px;
    font-weight: 700;
    color: #144C52;
}

.Card input,
.Card select,
.Card textarea,
.Filters select {
    width: 100%;
    border: 1px solid #c6d5d2;
    border-radius: 8px;
    padding: 10px;
    font-size: 15px;
    box-sizing: border-box;
}

.Card textarea {
    resize: vertical;
}

.Card button {
    margin-top: 18px;
}

.Card button:disabled {
    opacity: 0.65;
    cursor: not-allowed;
}

.SummaryGrid {
    max-width: 1100px;
    margin: 0 auto 18px;
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
    gap: 14px;
}

.SummaryCard {
    background: #ffffff;
    color: #20262f;
    border-radius: 12px;
    padding: 18px;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.18);
}

.SummaryCard span,
.SummaryCard small {
    display: block;
    color: #4c5965;
    font-size: 13px;
}

.SummaryCard strong {
    display: block;
    margin-top: 6px;
    font-size: 26px;
    color: #144C52;
    text-transform: capitalize;
}

.Filters {
    max-width: 1100px;
    margin: 0 auto 18px;
}

.Filters label {
    margin-top: 0;
}

.Panel {
    margin-bottom: 18px;
}

.TrendList {
    margin-top: 16px;
    display: grid;
    gap: 10px;
}

.TrendRow {
    display: grid;
    grid-template-columns: 110px 1fr 54px;
    gap: 12px;
    align-items: center;
    color: #4c5965;
    font-size: 14px;
}

.BarTrack {
    height: 12px;
    background: #e8efee;
    border-radius: 999px;
    overflow: hidden;
}

.BarFill {
    height: 100%;
    background: #144C52;
    border-radius: 999px;
}

.LogList {
    display: grid;
    gap: 14px;
}

.LogCard {
    border: 1px solid #e2ecea;
    border-radius: 10px;
    padding: 16px;
}

.LogTop {
    display: flex;
    justify-content: space-between;
    gap: 16px;
    align-items: flex-start;
}

.LogTop h3 {
    margin: 0 0 4px;
    color: #144C52;
}

.LogTop p,
.LogCard p {
    margin: 0 0 8px;
    color: #4c5965;
    line-height: 1.5;
}

.ScorePill {
    border-radius: 999px;
    background: #e8efee;
    color: #144C52;
    padding: 8px 12px;
    font-weight: 800;
    white-space: nowrap;
}

.MetricGrid {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin: 12px 0;
}

.MetricGrid span {
    background: #f4f7f7;
    color: #30404a;
    border-radius: 999px;
    padding: 6px 10px;
    font-size: 13px;
}

.Notes {
    background: #f4f7f7;
    border-left: 4px solid #144C52;
    padding: 10px 12px;
    border-radius: 6px;
}

.DeleteButton {
    border: 0;
    border-radius: 6px;
    background: #f00946;
    color: #ffffff;
    padding: 8px 12px;
    cursor: pointer;
    font-weight: 700;
}

.EmptyState {
    max-width: 1100px;
    margin: 0 auto 18px;
}

.EmptyState p {
    color: #4c5965;
    line-height: 1.5;
}

.Error,
.Success {
    border-radius: 8px;
    padding: 10px 12px;
    margin: 12px 0;
    font-weight: 700;
}

.Error {
    background: #ffe9ee;
    color: #a0002c;
}

.Success {
    background: #e8f6f2;
    color: #144C52;
}

@media (max-width: 850px) {
    .Header,
    .Layout {
        display: block;
    }

    .Header a {
        margin-top: 14px;
    }

    .Card {
        margin-bottom: 18px;
    }

    .TrendRow {
        grid-template-columns: 1fr;
        gap: 6px;
    }
}
CSS

node <<'NODE'
const fs = require('fs');

function replaceFile(file, replacer) {
  const before = fs.readFileSync(file, 'utf8');
  const after = replacer(before);
  if (after !== before) {
    fs.writeFileSync(file, after);
  }
}

replaceFile('index.js', content => {
  if (!content.includes("/api/wellbeing-logs")) {
    content = content.replace(
      "app.use('/api/game-attempts', require('./routes/gameAttempts'));",
      "app.use('/api/game-attempts', require('./routes/gameAttempts'));\napp.use('/api/wellbeing-logs', require('./routes/wellbeingLogs'));"
    );
  }
  return content;
});

replaceFile('client/src/App.js', content => {
  if (!content.includes("./components/Wellbeing/Wellbeing")) {
    content = content.replace(
      "import GameProgress from './components/GameProgress/GameProgress';",
      "import GameProgress from './components/GameProgress/GameProgress';\nimport Wellbeing from './components/Wellbeing/Wellbeing';"
    );
  }

  if (!content.includes('path="/wellbeing"')) {
    content = content.replace(
      '<ProtectedRoute path="/game-progress" exact component={GameProgress} />',
      '<ProtectedRoute path="/game-progress" exact component={GameProgress} />\n                <ProtectedRoute path="/wellbeing" exact component={Wellbeing} />'
    );
  }

  return content;
});

replaceFile('client/src/components/Dashboard/Dashboard.js', content => {
  if (!content.includes('Wellbeing tracker')) {
    const card = `
                    <div className={classes.Card}>
                        <h2>Wellbeing tracker</h2>
                        <p>Record sleep, sensory load, mood, communication, triggers, and helpful strategies.</p>
                        <Link to="/wellbeing">Open wellbeing tracker</Link>
                    </div>
`;
    content = content.replace(
      `                    <div className={classes.Card}>
                        <h2>Screening support</h2>
                        <p>Use the caregiver questionnaire for a non-diagnostic risk summary.</p>
                        <Link to="/screening/new">Start saved screening</Link>
                    </div>
`,
      card + `
                    <div className={classes.Card}>
                        <h2>Screening support</h2>
                        <p>Use the caregiver questionnaire for a non-diagnostic risk summary.</p>
                        <Link to="/screening/new">Start saved screening</Link>
                    </div>
`
    );
  }
  return content;
});

replaceFile('client/src/components/Navigation/NavigationItems/NavigationItems.js', content => {
  if (!content.includes('link="/wellbeing"')) {
    content = content.replace(
      `{auth.user ? <NavigationItem link="/game-progress">Progress</NavigationItem> : null}`,
      `{auth.user ? <NavigationItem link="/game-progress">Progress</NavigationItem> : null}\n                    {auth.user ? <NavigationItem link="/wellbeing">Wellbeing</NavigationItem> : null}`
    );
  }
  return content;
});

replaceFile('client/src/components/Navigation/SideDrawer/SideDrawer.js', content => {
  if (!content.includes('link="/wellbeing"')) {
    content = content.replace(
      `{auth.user ? <NavigationItem link="/game-progress">Progress</NavigationItem> : null}`,
      `{auth.user ? <NavigationItem link="/game-progress">Progress</NavigationItem> : null}\n                        {auth.user ? <NavigationItem link="/wellbeing">Wellbeing</NavigationItem> : null}`
    );
  }
  return content;
});
NODE

cat > docs/WELLBEING_TRACKER_NOTES.md <<'DOC'
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
DOC

echo "Phase 4 applied. Restart the app and open /wellbeing after logging in."
