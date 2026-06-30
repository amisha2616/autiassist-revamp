const router = require('express').Router();
const GameQuestion = require('../models/gameQuestion');

const mediaTypeByLevel = {
  1: 'image',
  2: 'audio',
  3: 'video'
};

function normalizeQuestionPayload(body) {
  const level = Number(body.level);
  return {
    level,
    mediaType: body.mediaType || mediaTypeByLevel[level],
    question: body.question,
    hostedURL: body.hostedURL,
    correct_answer: body.correct_answer,
    incorrect_answers: body.incorrect_answers,
    difficulty: body.difficulty || 'easy',
    tags: Array.isArray(body.tags) ? body.tags : [],
    source: body.source || 'manual'
  };
}

router.get('/', async (req, res) => {
  try {
    const filter = {};
    if (req.query.level) {
      filter.level = Number(req.query.level);
    }

    const questions = await GameQuestion.find(filter).sort({ createdAt: -1 });
    res.json(questions);
  } catch (error) {
    res.status(500).json({ message: 'Unable to fetch questions.', error: error.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const question = await GameQuestion.findById(req.params.id);

    if (!question) {
      return res.status(404).json({ message: 'Invalid question id.' });
    }

    res.json(question);
  } catch (error) {
    res.status(500).json({ message: 'Unable to fetch question.', error: error.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const question = await GameQuestion.create(normalizeQuestionPayload(req.body));
    res.status(201).json(question);
  } catch (error) {
    res.status(400).json({ message: 'Unable to create question.', error: error.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const question = await GameQuestion.findByIdAndUpdate(
      req.params.id,
      normalizeQuestionPayload(req.body),
      { new: true, runValidators: true }
    );

    if (!question) {
      return res.status(404).json({ message: 'Invalid question id.' });
    }

    res.json(question);
  } catch (error) {
    res.status(400).json({ message: 'Unable to update question.', error: error.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const question = await GameQuestion.findByIdAndDelete(req.params.id);

    if (!question) {
      return res.status(404).json({ message: 'Invalid question id.' });
    }

    res.json({ message: 'Question deleted successfully.' });
  } catch (error) {
    res.status(500).json({ message: 'Unable to delete question.', error: error.message });
  }
});

module.exports = router;
