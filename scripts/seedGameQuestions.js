const mongoose = require('mongoose');
const GameQuestion = require('../models/gameQuestion');
require('dotenv').config();

const mongoUrl = process.env.MONGODBURL || 'mongodb://127.0.0.1:27017/autismo';

const optionsByAnswer = {
  happy: ['sad', 'angry', 'neutral'],
  sad: ['happy', 'angry', 'neutral'],
  angry: ['happy', 'sad', 'neutral'],
  neutral: ['happy', 'sad', 'angry']
};

const questions = [
  {
    level: 1,
    mediaType: 'image',
    question: 'Which emotion is shown in this face?',
    hostedURL: '/demo-assets/happy.svg',
    correct_answer: 'happy',
    incorrect_answers: optionsByAnswer.happy,
    difficulty: 'easy',
    tags: ['demo', 'image'],
    source: 'demo'
  },
  {
    level: 1,
    mediaType: 'image',
    question: 'Which emotion is shown in this face?',
    hostedURL: '/demo-assets/sad.svg',
    correct_answer: 'sad',
    incorrect_answers: optionsByAnswer.sad,
    difficulty: 'easy',
    tags: ['demo', 'image'],
    source: 'demo'
  },
  {
    level: 1,
    mediaType: 'image',
    question: 'Which emotion is shown in this face?',
    hostedURL: '/demo-assets/angry.svg',
    correct_answer: 'angry',
    incorrect_answers: optionsByAnswer.angry,
    difficulty: 'easy',
    tags: ['demo', 'image'],
    source: 'demo'
  },
  {
    level: 2,
    mediaType: 'audio',
    question: 'Listen carefully. Which emotion does this sound represent?',
    hostedURL: '/demo-assets/happy-tone.wav',
    correct_answer: 'happy',
    incorrect_answers: optionsByAnswer.happy,
    difficulty: 'easy',
    tags: ['demo', 'audio'],
    source: 'demo'
  },
  {
    level: 2,
    mediaType: 'audio',
    question: 'Listen carefully. Which emotion does this sound represent?',
    hostedURL: '/demo-assets/sad-tone.wav',
    correct_answer: 'sad',
    incorrect_answers: optionsByAnswer.sad,
    difficulty: 'easy',
    tags: ['demo', 'audio'],
    source: 'demo'
  },
  {
    level: 2,
    mediaType: 'audio',
    question: 'Listen carefully. Which emotion does this sound represent?',
    hostedURL: '/demo-assets/angry-tone.wav',
    correct_answer: 'angry',
    incorrect_answers: optionsByAnswer.angry,
    difficulty: 'easy',
    tags: ['demo', 'audio'],
    source: 'demo'
  },
  {
    level: 3,
    mediaType: 'video',
    question: 'Watch the short clip. Which emotion best matches the scene?',
    hostedURL: '/demo-assets/social-scenario.mp4',
    correct_answer: 'happy',
    incorrect_answers: optionsByAnswer.happy,
    difficulty: 'easy',
    tags: ['demo', 'video'],
    source: 'demo'
  }
];

async function run() {
  await mongoose.connect(mongoUrl, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    useCreateIndex: true,
    useFindAndModify: false
  });

  await GameQuestion.deleteMany({ source: 'demo' });
  const inserted = await GameQuestion.insertMany(questions);
  console.log(`Seeded ${inserted.length} demo game questions.`);
  await mongoose.disconnect();
}

run().catch(async error => {
  console.error('Seed failed:', error.message);
  await mongoose.disconnect();
  process.exit(1);
});
