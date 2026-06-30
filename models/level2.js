const mongoose = require('mongoose');
require('mongoose-type-url');

const level2Schema = new mongoose.Schema({
    question: {
        type: String,
        required: true
    },

    hostedURL: {
        type: mongoose.SchemaTypes.Url
    },

    correct_answer: {
        type: String,
        required: true
    },

    incorrect_answers: {
        type: Array,
        required: true,
        maxlength: 3,
        minlength: 3
    }

});

const Level2 = mongoose.model('Level2', level2Schema);
module.exports = Level2;
