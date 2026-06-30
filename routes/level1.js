const router = require('express').Router();

// Imported class
const Level1 = require('../models/level1');

// Get all questions
router.get('/', async (req, res) => {
    try {
        const questions = await Level1.find();
        res.send(questions);
    }
    catch (error) {
        res.send(error);
    }
});

// Get 1 question
router.get('/:id', async (req, res) => {
    try {
        const _id = req.params.id;
        const question = await Level1.findById(_id);

        if (!question) {
            res.send('INVALID QUESTION ID');
        } else {
            res.send(question);
        }
    }
    catch (error) {
        res.send(error);
    }
});

// Create 1 question
router.post('/', async (req, res) => {
    try {
        let question = new Level1({
            question: req.body.question,
            hostedURL: req.body.hostedURL,
            correct_answer: req.body.correct_answer,
            incorrect_answers: req.body.incorrect_answers
        });

        question = await question.save();
        res.send(question);
    }
    catch (error) {
        res.send(error);
    }
});


// Update 1 question
router.put('/:id', async (req, res) => {
    try {
        const _id = req.params.id;
        let ques = await Level1.findById(_id);

        let {
            question: new_question,
            correct_answer: new_correct_answer,
            incorrect_answers: new_incorrect_answers
        } = req.body;

        ques.set({
            question: new_question,
            correct_answer: new_correct_answer,
            incorrect_answers: new_incorrect_answers
        });

        ques = await ques.save();
        res.send(ques);
    }
    catch (error) {
        res.send(error);
    }
});

// Delete 1 question
router.delete('/:id', async (req, res) => {
    try {
        const _id = req.params.id;
        const question = await Level1.deleteOne({ _id });

        if (question.deletedCount === 0) {
            res.send('INVALID QUESTION ID');
        } else {
            res.send('DELETED SUCCESSFULLY');
        }
    }
    catch (error) {
        res.send(error);
    }
});

module.exports = router;