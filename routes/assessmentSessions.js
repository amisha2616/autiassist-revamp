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
