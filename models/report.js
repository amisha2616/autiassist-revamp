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
