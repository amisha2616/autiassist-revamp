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
