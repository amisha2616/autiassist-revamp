const mongoose = require('mongoose');

const childProfileSchema = new mongoose.Schema(
  {
    caregiver: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    name: {
      type: String,
      required: true,
      trim: true,
      minlength: 2
    },
    nickname: {
      type: String,
      trim: true,
      default: ''
    },
    dateOfBirth: {
      type: Date
    },
    gender: {
      type: String,
      enum: ['female', 'male', 'other', 'prefer_not_to_say', ''],
      default: ''
    },
    notes: {
      type: String,
      trim: true,
      maxlength: 1000,
      default: ''
    },
    archived: {
      type: Boolean,
      default: false,
      index: true
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('ChildProfile', childProfileSchema);
