const mongoose = require('mongoose');
require('mongoose-type-url');

const level3Schema = new mongoose.Schema({
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

const Level3 = mongoose.model('Level3', level3Schema);
module.exports = Level3;