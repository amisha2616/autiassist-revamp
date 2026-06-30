import React from 'react';
import classes from './Question.module.css';

const Question = props => <div className={classes.QuestionFile}>{props.children}</div>;

export default Question;