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
