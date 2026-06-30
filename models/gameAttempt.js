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
