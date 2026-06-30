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
