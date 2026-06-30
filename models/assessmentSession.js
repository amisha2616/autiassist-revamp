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
