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
