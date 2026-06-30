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
