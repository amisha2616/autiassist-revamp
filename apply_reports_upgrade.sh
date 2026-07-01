#!/usr/bin/env bash
set -euo pipefail

if [ ! -f "package.json" ] || [ ! -d "client/src" ]; then
  echo "Run this script from the autismo-revamp-starter project root."
  exit 1
fi

if [ ! -f "middleware/auth.js" ] || [ ! -f "models/childProfile.js" ] || [ ! -f "models/assessmentSession.js" ]; then
  echo "Auth, profiles, and screening upgrades are required before this step. Apply earlier phases first."
  exit 1
fi

if [ ! -f "models/gameAttempt.js" ] || [ ! -f "models/wellbeingLog.js" ]; then
  echo "Game progress and wellbeing upgrades are required before this step. Apply phases 3 and 4 first."
  exit 1
fi

echo "Applying Phase 5: report generation and review-ready summary page..."

mkdir -p models routes client/src/components/Reports docs

cat > models/report.js <<'MODEL'
const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema(
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
    title: {
      type: String,
      required: true,
      trim: true,
      maxlength: 160
    },
    reportType: {
      type: String,
      enum: ['child-progress'],
      default: 'child-progress',
      index: true
    },
    dateRange: {
      from: {
        type: Date,
        default: null
      },
      to: {
        type: Date,
        default: null
      }
    },
    summary: {
      assessmentBand: {
        type: String,
        default: 'not_available'
      },
      assessmentScore: {
        type: Number,
        default: 0
      },
      gameAverageAccuracy: {
        type: Number,
        default: 0
      },
      wellbeingAverageScore: {
        type: Number,
        default: 0
      },
      totalAssessments: {
        type: Number,
        default: 0
      },
      totalGameAttempts: {
        type: Number,
        default: 0
      },
      totalWellbeingLogs: {
        type: Number,
        default: 0
      },
      professionalReviewRecommended: {
        type: Boolean,
        default: false
      }
    },
    snapshot: {
      type: mongoose.Schema.Types.Mixed,
      required: true
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Report', reportSchema);
MODEL

cat > routes/reports.js <<'ROUTE'
const router = require('express').Router();
const mongoose = require('mongoose');
const Report = require('../models/report');
const ChildProfile = require('../models/childProfile');
const AssessmentSession = require('../models/assessmentSession');
const GameAttempt = require('../models/gameAttempt');
const WellbeingLog = require('../models/wellbeingLog');
const { requireAuth } = require('../middleware/auth');

router.use(requireAuth);

const REPORT_DISCLAIMER = 'This report is generated from caregiver-entered information, screening responses, emotion-game practice, and wellbeing logs. It is for support and review only. It is not a medical diagnosis and should not replace evaluation by a qualified professional.';

function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(String(id));
}

function round(value) {
  if (!Number.isFinite(value)) {
    return 0;
  }
  return Math.round(value * 100) / 100;
}

function toPositiveInt(value, fallback, max) {
  const number = Number(value);
  if (!Number.isFinite(number) || number <= 0) {
    return fallback;
  }
  return Math.min(Math.floor(number), max);
}

function parseRangeDate(value, endOfDay) {
  if (!value) {
    return null;
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    const error = new Error('Use valid report date filters.');
    error.statusCode = 400;
    throw error;
  }

  if (endOfDay) {
    date.setHours(23, 59, 59, 999);
  } else {
    date.setHours(0, 0, 0, 0);
  }

  return date;
}

function dateCondition(field, fromDate, toDate) {
  const condition = {};

  if (fromDate) {
    condition.$gte = fromDate;
  }

  if (toDate) {
    condition.$lte = toDate;
  }

  if (!Object.keys(condition).length) {
    return {};
  }

  return { [field]: condition };
}

function ownerProfileQuery(req, extra) {
  if (req.user.role === 'admin') {
    return { ...extra };
  }
  return { caregiver: req.user._id, ...extra };
}

function ownerDocumentQuery(req, extra) {
  if (req.user.role === 'admin') {
    return { ...extra };
  }
  return { user: req.user._id, ...extra };
}

function reportOwnerQuery(req, extra) {
  if (req.user.role === 'admin') {
    return { ...extra };
  }
  return { user: req.user._id, ...extra };
}

async function ensureProfileAccess(req, profileId) {
  if (!profileId || !isValidObjectId(profileId)) {
    const error = new Error('Select a valid child profile before generating a report.');
    error.statusCode = 400;
    throw error;
  }

  const profile = await ChildProfile.findOne(ownerProfileQuery(req, { _id: profileId, archived: false })).lean();
  if (!profile) {
    const error = new Error('Profile not found or not accessible.');
    error.statusCode = 404;
    throw error;
  }

  return profile;
}

function countBands(assessments) {
  return assessments.reduce((counts, session) => {
    const band = session.band || 'not_available';
    counts[band] = (counts[band] || 0) + 1;
    return counts;
  }, { low: 0, moderate: 0, high: 0, not_available: 0 });
}

function summarizeAssessments(assessments) {
  const latest = assessments.length ? assessments[0] : null;

  return {
    totalSessions: assessments.length,
    latest: latest
      ? {
          id: latest._id,
          assessmentType: latest.assessmentType,
          score: latest.score,
          maxScore: latest.maxScore,
          band: latest.band,
          recommendation: latest.recommendation,
          createdAt: latest.createdAt
        }
      : null,
    bandCounts: countBands(assessments),
    recent: assessments.slice(0, 5).map(session => ({
      id: session._id,
      assessmentType: session.assessmentType,
      score: session.score,
      maxScore: session.maxScore,
      band: session.band,
      recommendation: session.recommendation,
      createdAt: session.createdAt
    }))
  };
}

function summarizeGameAttempts(attempts) {
  const totalAccuracy = attempts.reduce((sum, attempt) => sum + (Number(attempt.accuracy) || 0), 0);
  const bestAttempt = attempts.reduce((best, attempt) => {
    if (!best || Number(attempt.accuracy) > Number(best.accuracy)) {
      return attempt;
    }
    return best;
  }, null);

  const byLevel = [1, 2, 3].map(level => {
    const levelAttempts = attempts.filter(attempt => Number(attempt.level) === level);
    const levelTotal = levelAttempts.reduce((sum, attempt) => sum + (Number(attempt.accuracy) || 0), 0);
    const levelBest = levelAttempts.reduce((best, attempt) => {
      if (!best || Number(attempt.accuracy) > Number(best.accuracy)) {
        return attempt;
      }
      return best;
    }, null);

    return {
      level,
      attempts: levelAttempts.length,
      averageAccuracy: levelAttempts.length ? round(levelTotal / levelAttempts.length) : 0,
      bestAccuracy: levelBest ? round(Number(levelBest.accuracy) || 0) : 0,
      latestAccuracy: levelAttempts.length ? round(Number(levelAttempts[0].accuracy) || 0) : 0
    };
  });

  return {
    totalAttempts: attempts.length,
    averageAccuracy: attempts.length ? round(totalAccuracy / attempts.length) : 0,
    bestAccuracy: bestAttempt ? round(Number(bestAttempt.accuracy) || 0) : 0,
    byLevel,
    recent: attempts.slice(0, 6).map(attempt => ({
      id: attempt._id,
      level: attempt.level,
      score: attempt.score,
      maxScore: attempt.maxScore,
      totalQuestions: attempt.totalQuestions,
      correctAnswers: attempt.correctAnswers,
      accuracy: attempt.accuracy,
      completedAt: attempt.completedAt
    }))
  };
}

function mostFrequent(items) {
  const counts = items.reduce((acc, item) => {
    const key = String(item || '').trim();
    if (key) {
      acc[key] = (acc[key] || 0) + 1;
    }
    return acc;
  }, {});

  return Object.keys(counts).sort((a, b) => counts[b] - counts[a])[0] || 'not_available';
}

function topListItems(logs, fieldName) {
  const counts = {};

  logs.forEach(log => {
    const values = Array.isArray(log[fieldName]) ? log[fieldName] : [];
    values.forEach(value => {
      const key = String(value || '').trim();
      if (key) {
        counts[key] = (counts[key] || 0) + 1;
      }
    });
  });

  return Object.keys(counts)
    .sort((a, b) => counts[b] - counts[a])
    .slice(0, 6)
    .map(item => ({ label: item, count: counts[item] }));
}

function summarizeWellbeing(logs) {
  const totalOverall = logs.reduce((sum, log) => sum + (Number(log.overallScore) || 0), 0);
  const totalSleep = logs.reduce((sum, log) => sum + (Number(log.sleepQuality) || 0), 0);
  const totalSensory = logs.reduce((sum, log) => sum + (Number(log.sensoryOverload) || 0), 0);
  const totalCommunication = logs.reduce((sum, log) => sum + (Number(log.communicationEase) || 0), 0);
  const totalDistress = logs.reduce((sum, log) => sum + (Number(log.distressEpisodes) || 0), 0);

  return {
    totalLogs: logs.length,
    averageOverallScore: logs.length ? round(totalOverall / logs.length) : 0,
    averageSleepQuality: logs.length ? round(totalSleep / logs.length) : 0,
    averageSensoryOverload: logs.length ? round(totalSensory / logs.length) : 0,
    averageCommunicationEase: logs.length ? round(totalCommunication / logs.length) : 0,
    averageDistressEpisodes: logs.length ? round(totalDistress / logs.length) : 0,
    mostCommonMood: logs.length ? mostFrequent(logs.map(log => log.mood)) : 'not_available',
    commonTriggers: topListItems(logs, 'triggers'),
    helpfulStrategies: topListItems(logs, 'strategies'),
    latest: logs.length
      ? {
          id: logs[0]._id,
          logDate: logs[0].logDate,
          overallScore: logs[0].overallScore,
          mood: logs[0].mood,
          sleepQuality: logs[0].sleepQuality,
          sensoryOverload: logs[0].sensoryOverload,
          communicationEase: logs[0].communicationEase,
          socialInteraction: logs[0].socialInteraction,
          distressEpisodes: logs[0].distressEpisodes,
          triggers: logs[0].triggers,
          strategies: logs[0].strategies,
          notes: logs[0].notes
        }
      : null,
    trend: logs.slice(0, 14).reverse().map(log => ({
      id: log._id,
      logDate: log.logDate,
      overallScore: log.overallScore,
      mood: log.mood
    }))
  };
}

function buildRecommendations(assessmentSummary, gameSummary, wellbeingSummary) {
  const recommendations = [];
  const latestAssessment = assessmentSummary.latest;

  if (!latestAssessment) {
    recommendations.push('Complete a saved screening questionnaire to add a structured screening summary to this report.');
  } else if (latestAssessment.band === 'high') {
    recommendations.push('The latest screening result is in the high-likelihood band. A qualified professional review is strongly recommended.');
  } else if (latestAssessment.band === 'moderate') {
    recommendations.push('The latest screening result is in the moderate-likelihood band. Follow-up discussion with a professional or caregiver review is recommended.');
  } else {
    recommendations.push('The latest screening result is in the low-likelihood band. Continue regular developmental monitoring and update the report if concerns change.');
  }

  if (!gameSummary.totalAttempts) {
    recommendations.push('Play emotion-learning games regularly so progress can be tracked across image, audio, and video levels.');
  } else if (gameSummary.averageAccuracy < 60) {
    recommendations.push('Game accuracy is below 60 percent. Continue with easier practice items and use hints before moving to harder activities.');
  } else if (gameSummary.averageAccuracy >= 80) {
    recommendations.push('Emotion-game accuracy is strong. Consider gradually increasing difficulty and adding social-scenario videos.');
  } else {
    recommendations.push('Emotion-game progress is developing. Keep short, consistent practice sessions and review commonly missed emotions.');
  }

  if (!wellbeingSummary.totalLogs) {
    recommendations.push('Add wellbeing logs for sleep, sensory load, communication, mood, triggers, and helpful strategies.');
  } else if (wellbeingSummary.averageOverallScore < 60) {
    recommendations.push('Wellbeing scores suggest that recent days may need closer attention. Review triggers, sensory load, sleep, and calming strategies.');
  } else {
    recommendations.push('Wellbeing logs show usable trend data. Continue logging consistently so patterns are easier to discuss during review.');
  }

  recommendations.push('Use this report as a discussion aid only. It does not diagnose autism or replace clinical assessment.');

  return recommendations;
}

function buildStoredSummary(snapshot) {
  const latestAssessment = snapshot.assessmentSummary.latest;

  return {
    assessmentBand: latestAssessment ? latestAssessment.band : 'not_available',
    assessmentScore: latestAssessment ? latestAssessment.score : 0,
    gameAverageAccuracy: snapshot.gameSummary.averageAccuracy,
    wellbeingAverageScore: snapshot.wellbeingSummary.averageOverallScore,
    totalAssessments: snapshot.assessmentSummary.totalSessions,
    totalGameAttempts: snapshot.gameSummary.totalAttempts,
    totalWellbeingLogs: snapshot.wellbeingSummary.totalLogs,
    professionalReviewRecommended: latestAssessment ? ['moderate', 'high'].includes(latestAssessment.band) : false
  };
}

async function buildSnapshot(req, profile, options) {
  const fromDate = parseRangeDate(options.fromDate, false);
  const toDate = parseRangeDate(options.toDate, true);

  const assessmentFilter = ownerDocumentQuery(req, {
    profile: profile._id,
    ...dateCondition('createdAt', fromDate, toDate)
  });
  const gameFilter = ownerDocumentQuery(req, {
    profile: profile._id,
    ...dateCondition('completedAt', fromDate, toDate)
  });
  const wellbeingFilter = ownerDocumentQuery(req, {
    profile: profile._id,
    ...dateCondition('logDate', fromDate, toDate)
  });

  const [assessments, gameAttempts, wellbeingLogs] = await Promise.all([
    AssessmentSession.find(assessmentFilter)
      .sort({ createdAt: -1 })
      .limit(50)
      .lean(),
    GameAttempt.find(gameFilter)
      .sort({ completedAt: -1, createdAt: -1 })
      .limit(200)
      .lean(),
    WellbeingLog.find(wellbeingFilter)
      .sort({ logDate: -1, createdAt: -1 })
      .limit(200)
      .lean()
  ]);

  const assessmentSummary = summarizeAssessments(assessments);
  const gameSummary = summarizeGameAttempts(gameAttempts);
  const wellbeingSummary = summarizeWellbeing(wellbeingLogs);

  return {
    generatedAt: new Date(),
    generatedBy: {
      id: req.user._id,
      name: req.user.name,
      email: req.user.email,
      role: req.user.role
    },
    profile: {
      id: profile._id,
      name: profile.name,
      nickname: profile.nickname || '',
      dateOfBirth: profile.dateOfBirth || null,
      gender: profile.gender || '',
      notes: profile.notes || '',
      createdAt: profile.createdAt
    },
    dateRange: {
      from: fromDate,
      to: toDate
    },
    assessmentSummary,
    gameSummary,
    wellbeingSummary,
    recommendations: buildRecommendations(assessmentSummary, gameSummary, wellbeingSummary),
    disclaimer: REPORT_DISCLAIMER
  };
}

router.get('/overview', async (req, res) => {
  try {
    const profile = await ensureProfileAccess(req, req.query.profileId);
    const snapshot = await buildSnapshot(req, profile, {
      fromDate: req.query.fromDate,
      toDate: req.query.toDate
    });

    res.json(snapshot);
  } catch (error) {
    res.status(error.statusCode || 500).json({ message: error.message || 'Unable to build report overview.' });
  }
});

router.get('/my', async (req, res) => {
  try {
    const limit = toPositiveInt(req.query.limit, 30, 100);
    const filter = reportOwnerQuery(req, {});

    if (req.query.profileId) {
      const profile = await ensureProfileAccess(req, req.query.profileId);
      filter.profile = profile._id;
    }

    const reports = await Report.find(filter)
      .sort({ createdAt: -1 })
      .limit(limit)
      .populate('profile', 'name nickname')
      .lean();

    res.json(reports);
  } catch (error) {
    res.status(error.statusCode || 500).json({ message: error.message || 'Unable to load reports.' });
  }
});

router.post('/generate', async (req, res) => {
  try {
    const profile = await ensureProfileAccess(req, req.body.profileId);
    const snapshot = await buildSnapshot(req, profile, {
      fromDate: req.body.fromDate,
      toDate: req.body.toDate
    });

    const title = String(req.body.title || `${profile.name} progress report`).trim().slice(0, 160);

    const report = await Report.create({
      user: req.user._id,
      profile: profile._id,
      title: title || `${profile.name} progress report`,
      reportType: 'child-progress',
      dateRange: snapshot.dateRange,
      summary: buildStoredSummary(snapshot),
      snapshot
    });

    const populatedReport = await Report.findById(report._id)
      .populate('profile', 'name nickname')
      .lean();

    res.status(201).json(populatedReport);
  } catch (error) {
    res.status(error.statusCode || 500).json({ message: error.message || 'Unable to generate report.' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    if (!isValidObjectId(req.params.id)) {
      return res.status(400).json({ message: 'Invalid report id.' });
    }

    const report = await Report.findOne(reportOwnerQuery(req, { _id: req.params.id }))
      .populate('profile', 'name nickname')
      .lean();

    if (!report) {
      return res.status(404).json({ message: 'Report not found.' });
    }

    res.json(report);
  } catch (error) {
    res.status(500).json({ message: 'Unable to load report.', error: error.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    if (!isValidObjectId(req.params.id)) {
      return res.status(400).json({ message: 'Invalid report id.' });
    }

    const report = await Report.findOneAndDelete(reportOwnerQuery(req, { _id: req.params.id }));
    if (!report) {
      return res.status(404).json({ message: 'Report not found.' });
    }

    res.json({ message: 'Report deleted.' });
  } catch (error) {
    res.status(500).json({ message: 'Unable to delete report.', error: error.message });
  }
});

module.exports = router;
ROUTE

cat > client/src/components/Reports/Reports.js <<'REACT'
import React, { Component } from 'react';
import axios from 'axios';
import { Link } from 'react-router-dom';
import classes from './Reports.module.css';

class Reports extends Component {
    state = {
        profiles: [],
        reports: [],
        selectedProfileId: '',
        overview: null,
        selectedReport: null,
        fromDate: '',
        toDate: '',
        loading: true,
        generating: false,
        error: '',
        success: ''
    };

    componentDidMount() {
        this.loadInitialData();
    }

    loadInitialData = async () => {
        this.setState({ loading: true, error: '', success: '' });

        try {
            const profilesResponse = await axios.get('/api/profiles');
            const profiles = profilesResponse.data || [];
            const firstProfileId = profiles.length ? profiles[0]._id : '';

            this.setState({
                profiles,
                selectedProfileId: firstProfileId,
                loading: false
            }, () => {
                if (firstProfileId) {
                    this.loadReportData();
                }
            });
        } catch (error) {
            const message = this.getErrorMessage(error, 'Unable to load profiles.');
            this.setState({ loading: false, error: message });
        }
    };

    getErrorMessage(error, fallback) {
        if (error.response && error.response.data && error.response.data.message) {
            return error.response.data.message;
        }
        return fallback;
    }

    loadReportData = async () => {
        if (!this.state.selectedProfileId) {
            return;
        }

        const params = {
            profileId: this.state.selectedProfileId
        };

        if (this.state.fromDate) {
            params.fromDate = this.state.fromDate;
        }

        if (this.state.toDate) {
            params.toDate = this.state.toDate;
        }

        this.setState({ loading: true, error: '', success: '', selectedReport: null });

        try {
            const responses = await Promise.all([
                axios.get('/api/reports/overview', { params }),
                axios.get('/api/reports/my', { params: { profileId: this.state.selectedProfileId, limit: 30 } })
            ]);

            this.setState({
                overview: responses[0].data,
                reports: responses[1].data || [],
                loading: false
            });
        } catch (error) {
            const message = this.getErrorMessage(error, 'Unable to load report data.');
            this.setState({ loading: false, error: message });
        }
    };

    inputHandler = event => {
        const name = event.target.name;
        const value = event.target.value;
        this.setState({ [name]: value, error: '', success: '' });
    };

    profileChangeHandler = event => {
        this.setState({ selectedProfileId: event.target.value, error: '', success: '' }, this.loadReportData);
    };

    filterSubmitHandler = event => {
        event.preventDefault();
        this.loadReportData();
    };

    clearFilters = () => {
        this.setState({ fromDate: '', toDate: '' }, this.loadReportData);
    };

    generateReport = async () => {
        if (!this.state.selectedProfileId) {
            this.setState({ error: 'Create and select a child profile before generating a report.' });
            return;
        }

        this.setState({ generating: true, error: '', success: '' });

        try {
            const payload = {
                profileId: this.state.selectedProfileId,
                fromDate: this.state.fromDate,
                toDate: this.state.toDate
            };
            const response = await axios.post('/api/reports/generate', payload);

            this.setState({
                generating: false,
                selectedReport: response.data,
                success: 'Report generated and saved.'
            }, this.loadSavedReports);
        } catch (error) {
            const message = this.getErrorMessage(error, 'Unable to generate report.');
            this.setState({ generating: false, error: message });
        }
    };

    loadSavedReports = async () => {
        if (!this.state.selectedProfileId) {
            return;
        }

        try {
            const response = await axios.get('/api/reports/my', {
                params: {
                    profileId: this.state.selectedProfileId,
                    limit: 30
                }
            });
            this.setState({ reports: response.data || [] });
        } catch (error) {
            this.setState({ error: this.getErrorMessage(error, 'Unable to refresh saved reports.') });
        }
    };

    viewReport = async reportId => {
        try {
            const response = await axios.get(`/api/reports/${reportId}`);
            this.setState({ selectedReport: response.data, success: 'Showing saved report snapshot.', error: '' });
        } catch (error) {
            this.setState({ error: this.getErrorMessage(error, 'Unable to load saved report.') });
        }
    };

    deleteReport = async reportId => {
        const confirmed = window.confirm('Delete this saved report?');
        if (!confirmed) {
            return;
        }

        try {
            await axios.delete(`/api/reports/${reportId}`);
            this.setState({ selectedReport: null, success: 'Report deleted.', error: '' }, this.loadSavedReports);
        } catch (error) {
            this.setState({ error: this.getErrorMessage(error, 'Unable to delete report.') });
        }
    };

    printReport = () => {
        window.print();
    };

    activeSnapshot() {
        if (this.state.selectedReport && this.state.selectedReport.snapshot) {
            return this.state.selectedReport.snapshot;
        }
        return this.state.overview;
    }

    formatDate(date) {
        if (!date) {
            return 'Not available';
        }
        return new Date(date).toLocaleDateString();
    }

    formatDateTime(date) {
        if (!date) {
            return 'Not available';
        }
        return new Date(date).toLocaleString();
    }

    formatBand(band) {
        if (!band || band === 'not_available') {
            return 'No screening yet';
        }
        return String(band).replace(/_/g, ' ');
    }

    formatMood(mood) {
        if (!mood || mood === 'not_available') {
            return 'No data';
        }
        return String(mood).replace(/_/g, ' ');
    }

    scoreLabel(value, suffix) {
        const number = Number(value);
        if (!Number.isFinite(number) || number === 0) {
            return 'No data';
        }
        return `${number}${suffix || ''}`;
    }

    bandClassName(band) {
        const value = String(band || '').toLowerCase();
        if (value === 'high') {
            return [classes.Band, classes.BandHigh].join(' ');
        }
        if (value === 'moderate') {
            return [classes.Band, classes.BandModerate].join(' ');
        }
        if (value === 'low') {
            return [classes.Band, classes.BandLow].join(' ');
        }
        return classes.Band;
    }

    renderControls() {
        return (
            <section className={[classes.Controls, classes.NoPrint].join(' ')}>
                <div className={classes.ControlGrid}>
                    <label>
                        Child profile
                        <select name="selectedProfileId" value={this.state.selectedProfileId} onChange={this.profileChangeHandler}>
                            {this.state.profiles.map(profile => (
                                <option value={profile._id} key={profile._id}>{profile.name}{profile.nickname ? ` (${profile.nickname})` : ''}</option>
                            ))}
                        </select>
                    </label>

                    <form className={classes.FilterForm} onSubmit={this.filterSubmitHandler}>
                        <label>
                            From
                            <input type="date" name="fromDate" value={this.state.fromDate} onChange={this.inputHandler} />
                        </label>
                        <label>
                            To
                            <input type="date" name="toDate" value={this.state.toDate} onChange={this.inputHandler} />
                        </label>
                        <div className={classes.FilterButtons}>
                            <button type="submit">Apply</button>
                            <button type="button" onClick={this.clearFilters}>Clear</button>
                        </div>
                    </form>
                </div>

                <div className={classes.ActionRow}>
                    <button type="button" onClick={this.generateReport} disabled={this.state.generating}>
                        {this.state.generating ? 'Generating...' : 'Generate saved report'}
                    </button>
                    <button type="button" onClick={this.printReport}>Print or save as PDF</button>
                    <Link to="/dashboard">Back to dashboard</Link>
                </div>
            </section>
        );
    }

    renderSummaryCards(snapshot) {
        const assessment = snapshot.assessmentSummary || {};
        const latestAssessment = assessment.latest;
        const game = snapshot.gameSummary || {};
        const wellbeing = snapshot.wellbeingSummary || {};

        return (
            <section className={classes.SummaryGrid}>
                <div className={classes.SummaryCard}>
                    <span>Latest screening</span>
                    <strong className={this.bandClassName(latestAssessment ? latestAssessment.band : '')}>{this.formatBand(latestAssessment ? latestAssessment.band : '')}</strong>
                    <small>{latestAssessment ? `${latestAssessment.score}/${latestAssessment.maxScore}` : 'No saved screening'}</small>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Game attempts</span>
                    <strong>{game.totalAttempts || 0}</strong>
                    <small>Average accuracy: {this.scoreLabel(game.averageAccuracy, '%')}</small>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Wellbeing logs</span>
                    <strong>{wellbeing.totalLogs || 0}</strong>
                    <small>Average score: {this.scoreLabel(wellbeing.averageOverallScore, '%')}</small>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Report generated</span>
                    <strong>{this.formatDate(snapshot.generatedAt)}</strong>
                    <small>{snapshot.generatedBy ? `By ${snapshot.generatedBy.name}` : 'Current preview'}</small>
                </div>
            </section>
        );
    }

    renderProfileSection(snapshot) {
        const profile = snapshot.profile || {};

        return (
            <section className={classes.ReportSection}>
                <h2>Profile details</h2>
                <div className={classes.DetailGrid}>
                    <div><span>Name</span><strong>{profile.name || 'Not available'}</strong></div>
                    <div><span>Nickname</span><strong>{profile.nickname || 'Not added'}</strong></div>
                    <div><span>Date of birth</span><strong>{this.formatDate(profile.dateOfBirth)}</strong></div>
                    <div><span>Gender</span><strong>{profile.gender ? profile.gender.replace(/_/g, ' ') : 'Not added'}</strong></div>
                </div>
                {profile.notes ? <p className={classes.NoteBox}>{profile.notes}</p> : null}
            </section>
        );
    }

    renderAssessmentSection(snapshot) {
        const assessment = snapshot.assessmentSummary || {};
        const latest = assessment.latest;

        return (
            <section className={classes.ReportSection}>
                <h2>Screening summary</h2>
                {!latest ? (
                    <p className={classes.EmptyText}>No saved screening result is available for this profile yet.</p>
                ) : (
                    <div>
                        <div className={classes.HighlightRow}>
                            <span className={this.bandClassName(latest.band)}>{this.formatBand(latest.band)}</span>
                            <strong>{latest.score}/{latest.maxScore}</strong>
                            <span>{this.formatDateTime(latest.createdAt)}</span>
                        </div>
                        <p>{latest.recommendation}</p>
                    </div>
                )}

                {assessment.recent && assessment.recent.length ? (
                    <div className={classes.SmallList}>
                        <h3>Recent screening history</h3>
                        {assessment.recent.map(session => (
                            <div className={classes.ListRow} key={session.id}>
                                <span>{this.formatDate(session.createdAt)}</span>
                                <strong>{this.formatBand(session.band)}</strong>
                                <small>{session.score}/{session.maxScore}</small>
                            </div>
                        ))}
                    </div>
                ) : null}
            </section>
        );
    }

    renderGameSection(snapshot) {
        const game = snapshot.gameSummary || {};
        const byLevel = game.byLevel || [];

        return (
            <section className={classes.ReportSection}>
                <h2>Emotion-game progress</h2>
                <div className={classes.DetailGrid}>
                    <div><span>Total attempts</span><strong>{game.totalAttempts || 0}</strong></div>
                    <div><span>Average accuracy</span><strong>{this.scoreLabel(game.averageAccuracy, '%')}</strong></div>
                    <div><span>Best accuracy</span><strong>{this.scoreLabel(game.bestAccuracy, '%')}</strong></div>
                </div>

                {byLevel.length ? (
                    <div className={classes.LevelGrid}>
                        {byLevel.map(level => (
                            <div className={classes.LevelCard} key={level.level}>
                                <h3>Level {level.level}</h3>
                                <p>{level.attempts} attempts</p>
                                <strong>{this.scoreLabel(level.averageAccuracy, '%')}</strong>
                                <small>Best: {this.scoreLabel(level.bestAccuracy, '%')}</small>
                            </div>
                        ))}
                    </div>
                ) : <p className={classes.EmptyText}>No game attempts have been saved yet.</p>}
            </section>
        );
    }

    renderWellbeingSection(snapshot) {
        const wellbeing = snapshot.wellbeingSummary || {};
        const latest = wellbeing.latest;
        const triggers = wellbeing.commonTriggers || [];
        const strategies = wellbeing.helpfulStrategies || [];

        return (
            <section className={classes.ReportSection}>
                <h2>Wellbeing tracker summary</h2>
                <div className={classes.DetailGrid}>
                    <div><span>Total logs</span><strong>{wellbeing.totalLogs || 0}</strong></div>
                    <div><span>Average wellbeing</span><strong>{this.scoreLabel(wellbeing.averageOverallScore, '%')}</strong></div>
                    <div><span>Common mood</span><strong>{this.formatMood(wellbeing.mostCommonMood)}</strong></div>
                    <div><span>Avg sensory overload</span><strong>{this.scoreLabel(wellbeing.averageSensoryOverload, '/5')}</strong></div>
                </div>

                {latest ? (
                    <div className={classes.NoteBox}>
                        <strong>Latest log: {this.formatDate(latest.logDate)} - {latest.overallScore}%</strong>
                        <p>Mood: {this.formatMood(latest.mood)}. Distress episodes: {latest.distressEpisodes}.</p>
                        {latest.notes ? <p>{latest.notes}</p> : null}
                    </div>
                ) : <p className={classes.EmptyText}>No wellbeing logs have been saved yet.</p>}

                <div className={classes.TwoColumnList}>
                    <div>
                        <h3>Common triggers</h3>
                        {triggers.length ? triggers.map(item => <span className={classes.Pill} key={item.label}>{item.label} ({item.count})</span>) : <p className={classes.EmptyText}>No trigger data yet.</p>}
                    </div>
                    <div>
                        <h3>Helpful strategies</h3>
                        {strategies.length ? strategies.map(item => <span className={classes.Pill} key={item.label}>{item.label} ({item.count})</span>) : <p className={classes.EmptyText}>No strategy data yet.</p>}
                    </div>
                </div>
            </section>
        );
    }

    renderRecommendations(snapshot) {
        const recommendations = snapshot.recommendations || [];

        return (
            <section className={classes.ReportSection}>
                <h2>Suggested review points</h2>
                <ol className={classes.Recommendations}>
                    {recommendations.map((item, index) => (
                        <li key={`${item}-${index}`}>{item}</li>
                    ))}
                </ol>
                <p className={classes.Disclaimer}>{snapshot.disclaimer}</p>
            </section>
        );
    }

    renderSavedReports() {
        return (
            <aside className={[classes.SavedReports, classes.NoPrint].join(' ')}>
                <h2>Saved reports</h2>
                {!this.state.reports.length ? <p>No saved reports yet. Generate one from the current preview.</p> : null}
                {this.state.reports.map(report => (
                    <div className={classes.SavedReport} key={report._id}>
                        <h3>{report.title}</h3>
                        <p>{this.formatDateTime(report.createdAt)}</p>
                        <p>
                            Screening: {this.formatBand(report.summary ? report.summary.assessmentBand : '')} | Game avg: {report.summary ? report.summary.gameAverageAccuracy : 0}% | Wellbeing: {report.summary ? report.summary.wellbeingAverageScore : 0}%
                        </p>
                        <div>
                            <button type="button" onClick={() => this.viewReport(report._id)}>View</button>
                            <button type="button" onClick={() => this.deleteReport(report._id)}>Delete</button>
                        </div>
                    </div>
                ))}
            </aside>
        );
    }

    renderReportPaper() {
        const snapshot = this.activeSnapshot();

        if (!snapshot) {
            return null;
        }

        const isSavedSnapshot = Boolean(this.state.selectedReport);

        return (
            <article className={classes.ReportPaper}>
                <div className={classes.ReportHeader}>
                    <div>
                        <p>AUTIASSIST SUPPORT REPORT</p>
                        <h1>{snapshot.profile ? snapshot.profile.name : 'Child'} progress summary</h1>
                        <span>{isSavedSnapshot ? 'Saved report snapshot' : 'Live preview from latest data'}</span>
                    </div>
                    <div className={classes.GeneratedBox}>
                        <strong>{this.formatDate(snapshot.generatedAt)}</strong>
                        <small>{this.formatDateTime(snapshot.generatedAt)}</small>
                    </div>
                </div>

                {this.renderSummaryCards(snapshot)}
                {this.renderProfileSection(snapshot)}
                {this.renderAssessmentSection(snapshot)}
                {this.renderGameSection(snapshot)}
                {this.renderWellbeingSection(snapshot)}
                {this.renderRecommendations(snapshot)}
            </article>
        );
    }

    render() {
        if (!this.state.profiles.length && !this.state.loading) {
            return (
                <div className={classes.Page}>
                    <section className={classes.EmptyState}>
                        <h1>Reports need a child profile first</h1>
                        <p>Create a child profile, then complete screenings, games, and wellbeing logs to build a review-ready report.</p>
                        <Link to="/profiles">Create profile</Link>
                    </section>
                </div>
            );
        }

        return (
            <div className={classes.Page}>
                <header className={[classes.Header, classes.NoPrint].join(' ')}>
                    <div>
                        <h1>Reports</h1>
                        <p>Generate a review-ready summary from screening results, emotion-game progress, and wellbeing logs.</p>
                    </div>
                </header>

                {this.renderControls()}

                {this.state.error ? <div className={[classes.Alert, classes.Error, classes.NoPrint].join(' ')}>{this.state.error}</div> : null}
                {this.state.success ? <div className={[classes.Alert, classes.Success, classes.NoPrint].join(' ')}>{this.state.success}</div> : null}
                {this.state.loading ? <div className={[classes.Alert, classes.NoPrint].join(' ')}>Loading report data...</div> : null}

                <div className={classes.Layout}>
                    <main>
                        {this.renderReportPaper()}
                    </main>
                    {this.renderSavedReports()}
                </div>
            </div>
        );
    }
}

export default Reports;
REACT

cat > client/src/components/Reports/Reports.module.css <<'CSS'
.Page {
    min-height: calc(100vh - 56px);
    padding: 96px 32px 48px;
    background: #20262f;
    color: #ffffff;
}

.Header,
.Controls,
.Layout,
.Alert,
.EmptyState {
    max-width: 1180px;
    margin-left: auto;
    margin-right: auto;
}

.Header {
    margin-bottom: 20px;
}

.Header h1,
.EmptyState h1 {
    margin: 0 0 8px;
    font-size: 36px;
}

.Header p,
.EmptyState p {
    margin: 0;
    color: #d6e4e2;
    line-height: 1.5;
}

.Controls,
.EmptyState {
    background: #ffffff;
    color: #20262f;
    border-radius: 14px;
    padding: 22px;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.22);
    margin-bottom: 18px;
}

.ControlGrid {
    display: grid;
    grid-template-columns: 280px 1fr;
    gap: 18px;
    align-items: end;
}

.Controls label {
    display: block;
    color: #144C52;
    font-weight: 800;
}

.Controls select,
.Controls input {
    width: 100%;
    box-sizing: border-box;
    border: 1px solid #c6d5d2;
    border-radius: 8px;
    padding: 10px;
    font-size: 15px;
    margin-top: 6px;
}

.FilterForm {
    display: grid;
    grid-template-columns: 1fr 1fr auto;
    gap: 12px;
    align-items: end;
}

.FilterButtons,
.ActionRow,
.SavedReport div {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
}

.ActionRow {
    margin-top: 18px;
}

.Controls button,
.Controls a,
.EmptyState a,
.SavedReport button {
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

.Controls button:disabled {
    opacity: 0.65;
    cursor: not-allowed;
}

.Layout {
    display: grid;
    grid-template-columns: 1fr 320px;
    gap: 18px;
    align-items: start;
}

.ReportPaper,
.SavedReports {
    background: #ffffff;
    color: #20262f;
    border-radius: 14px;
    padding: 26px;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.22);
}

.ReportHeader {
    display: flex;
    justify-content: space-between;
    gap: 20px;
    border-bottom: 1px solid #e2ecea;
    padding-bottom: 18px;
    margin-bottom: 22px;
}

.ReportHeader p {
    margin: 0 0 8px;
    color: #144C52;
    font-weight: 900;
    letter-spacing: 1px;
}

.ReportHeader h1 {
    margin: 0 0 8px;
    color: #144C52;
    font-size: 30px;
}

.ReportHeader span,
.GeneratedBox small {
    color: #4c5965;
}

.GeneratedBox {
    text-align: right;
    min-width: 150px;
}

.GeneratedBox strong {
    display: block;
    color: #144C52;
    font-size: 18px;
}

.SummaryGrid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
    gap: 14px;
    margin-bottom: 22px;
}

.SummaryCard {
    border: 1px solid #e2ecea;
    border-radius: 12px;
    padding: 16px;
}

.SummaryCard span,
.SummaryCard small,
.DetailGrid span,
.ListRow span,
.ListRow small,
.LevelCard small {
    display: block;
    color: #4c5965;
    font-size: 13px;
}

.SummaryCard strong {
    display: block;
    margin-top: 6px;
    color: #144C52;
    font-size: 24px;
    text-transform: capitalize;
}

.ReportSection {
    border-top: 1px solid #e2ecea;
    padding-top: 22px;
    margin-top: 22px;
}

.ReportSection h2 {
    margin: 0 0 14px;
    color: #144C52;
}

.ReportSection h3 {
    color: #144C52;
    margin: 16px 0 8px;
}

.ReportSection p {
    color: #4c5965;
    line-height: 1.55;
}

.DetailGrid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
    gap: 12px;
}

.DetailGrid div,
.LevelCard,
.NoteBox,
.ListRow {
    border: 1px solid #e2ecea;
    border-radius: 10px;
    padding: 14px;
}

.DetailGrid strong,
.LevelCard strong {
    display: block;
    color: #144C52;
    margin-top: 4px;
    text-transform: capitalize;
}

.NoteBox {
    background: #f5faf9;
    margin-top: 14px;
    color: #4c5965;
}

.HighlightRow {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 12px;
    margin-bottom: 12px;
}

.Band {
    display: inline-block;
    border-radius: 999px;
    padding: 7px 11px;
    background: #e8efee;
    color: #144C52;
    font-weight: 900;
    text-transform: capitalize;
}

.BandLow {
    background: #e6f4ec;
    color: #0c5f35;
}

.BandModerate {
    background: #fff3d8;
    color: #8a5a00;
}

.BandHigh {
    background: #ffe5e5;
    color: #9c1c1c;
}

.SmallList,
.LevelGrid,
.TwoColumnList {
    margin-top: 16px;
}

.SmallList {
    display: grid;
    gap: 8px;
}

.ListRow {
    display: grid;
    grid-template-columns: 1fr 1fr auto;
    gap: 10px;
    align-items: center;
}

.LevelGrid,
.TwoColumnList {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(170px, 1fr));
    gap: 12px;
}

.LevelCard h3,
.LevelCard p {
    margin: 0 0 6px;
}

.Pill {
    display: inline-block;
    margin: 0 8px 8px 0;
    border-radius: 999px;
    background: #e8efee;
    color: #144C52;
    padding: 7px 10px;
    font-weight: 700;
    font-size: 13px;
}

.Recommendations {
    margin: 0;
    padding-left: 22px;
    color: #4c5965;
    line-height: 1.6;
}

.Disclaimer {
    background: #fff3d8;
    border-radius: 10px;
    padding: 14px;
    color: #4c5965;
    font-weight: 700;
}

.SavedReports h2 {
    color: #144C52;
    margin: 0 0 12px;
}

.SavedReports p {
    color: #4c5965;
    line-height: 1.4;
}

.SavedReport {
    border: 1px solid #e2ecea;
    border-radius: 10px;
    padding: 14px;
    margin-bottom: 12px;
}

.SavedReport h3 {
    margin: 0 0 6px;
    color: #144C52;
}

.SavedReport p {
    margin: 0 0 8px;
    font-size: 14px;
}

.Alert {
    border-radius: 10px;
    padding: 14px;
    margin-bottom: 18px;
    background: #ffffff;
    color: #20262f;
}

.Error {
    border-left: 5px solid #f00946;
}

.Success {
    border-left: 5px solid #144C52;
}

.EmptyText {
    color: #6b7884;
}

@media (max-width: 900px) {
    .ControlGrid,
    .FilterForm,
    .Layout {
        grid-template-columns: 1fr;
    }

    .ReportHeader {
        display: block;
    }

    .GeneratedBox {
        text-align: left;
        margin-top: 12px;
    }
}

@media print {
    .NoPrint,
    .SavedReports {
        display: none !important;
    }

    .Page {
        padding: 0;
        background: #ffffff;
        color: #000000;
    }

    .Layout {
        display: block;
        max-width: none;
        margin: 0;
    }

    .ReportPaper {
        box-shadow: none;
        border-radius: 0;
        padding: 0;
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
  if (!content.includes("/api/reports")) {
    const anchor = "app.use('/api/wellbeing-logs', require('./routes/wellbeingLogs'));";
    if (content.includes(anchor)) {
      content = content.replace(anchor, `${anchor}\napp.use('/api/reports', require('./routes/reports'));`);
    } else {
      content = content.replace(
        "app.use('/api/game-questions', require('./routes/gameQuestions'));",
        "app.use('/api/reports', require('./routes/reports'));\napp.use('/api/game-questions', require('./routes/gameQuestions'));"
      );
    }
  }
  return content;
});

replaceFile('client/src/App.js', content => {
  if (!content.includes("./components/Reports/Reports")) {
    content = content.replace(
      "import Wellbeing from './components/Wellbeing/Wellbeing';",
      "import Wellbeing from './components/Wellbeing/Wellbeing';\nimport Reports from './components/Reports/Reports';"
    );
  }

  if (!content.includes('path="/reports"')) {
    content = content.replace(
      '<ProtectedRoute path="/wellbeing" exact component={Wellbeing} />',
      '<ProtectedRoute path="/wellbeing" exact component={Wellbeing} />\n                <ProtectedRoute path="/reports" exact component={Reports} />'
    );
  }

  return content;
});

replaceFile('client/src/components/Dashboard/Dashboard.js', content => {
  if (!content.includes('Review reports')) {
    const card = `
                    <div className={classes.Card}>
                        <h2>Review reports</h2>
                        <p>Generate a print-ready summary from profiles, screening results, games, and wellbeing logs.</p>
                        <Link to="/reports">Open reports</Link>
                    </div>
`;
    const anchor = `                    <div className={classes.Card}>
                        <h2>Wellbeing tracker</h2>
                        <p>Record sleep, sensory load, mood, communication, triggers, and helpful strategies.</p>
                        <Link to="/wellbeing">Open wellbeing tracker</Link>
                    </div>
`;
    if (content.includes(anchor)) {
      content = content.replace(anchor, anchor + card);
    } else {
      content = content.replace(
        `                    <div className={classes.Card}>
                        <h2>Screening support</h2>`,
        card + `
                    <div className={classes.Card}>
                        <h2>Screening support</h2>`
      );
    }
  }
  return content;
});

replaceFile('client/src/components/Navigation/NavigationItems/NavigationItems.js', content => {
  if (!content.includes('link="/reports"')) {
    content = content.replace(
      `{auth.user ? <NavigationItem link="/wellbeing">Wellbeing</NavigationItem> : null}`,
      `{auth.user ? <NavigationItem link="/wellbeing">Wellbeing</NavigationItem> : null}\n                    {auth.user ? <NavigationItem link="/reports">Reports</NavigationItem> : null}`
    );
  }
  return content;
});

replaceFile('client/src/components/Navigation/SideDrawer/SideDrawer.js', content => {
  if (!content.includes('link="/reports"')) {
    content = content.replace(
      `{auth.user ? <NavigationItem link="/wellbeing">Wellbeing</NavigationItem> : null}`,
      `{auth.user ? <NavigationItem link="/wellbeing">Wellbeing</NavigationItem> : null}\n                        {auth.user ? <NavigationItem link="/reports">Reports</NavigationItem> : null}`
    );
  }
  return content;
});
NODE

cat > docs/REPORT_GENERATION_NOTES.md <<'DOC'
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
DOC

echo "Phase 5 applied. Restart the app and open /reports after logging in."
