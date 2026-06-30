const mongoose = require('mongoose');

const allowedEmotions = [
  'happy',
  'sad',
  'angry',
  'fear',
  'surprise',
  'disgust',
  'neutral',
  'crying'
];

const gameQuestionSchema = new mongoose.Schema(
  {
    level: {
      type: Number,
      enum: [1, 2, 3],
      required: true,
      index: true
    },
    mediaType: {
      type: String,
      enum: ['image', 'audio', 'video'],
      required: true
    },
    question: {
      type: String,
      required: true,
      trim: true
    },
    hostedURL: {
      type: String,
      required: true,
      trim: true
    },
    correct_answer: {
      type: String,
      enum: allowedEmotions,
      required: true
    },
    incorrect_answers: {
      type: [String],
      required: true,
      validate: {
        validator: answers => Array.isArray(answers) && answers.length === 3,
        message: 'Exactly three incorrect answers are required.'
      }
    },
    difficulty: {
      type: String,
      enum: ['easy', 'medium', 'hard'],
      default: 'easy'
    },
    tags: {
      type: [String],
      default: []
    },
    source: {
      type: String,
      default: 'manual'
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('GameQuestion', gameQuestionSchema);
