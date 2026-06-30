const mongoose = require('mongoose');
require('mongoose-type-url');

const level1Schema = new mongoose.Schema({

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

const Level1 = mongoose.model('Level1', level1Schema);
module.exports = Level1;
