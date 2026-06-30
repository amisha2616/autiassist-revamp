import React from 'react';
import classes from './Option.module.css';

const Option = props => {
    let optionClasses = [classes.Option];
    if (props.showAnswer && props.answer === props.optionVal) {
        optionClasses.push(classes.CorrectAnswer);
    }
    else if (props.showAnswer && props.answer !== props.optionVal) {
        optionClasses.push(classes.IncorrectAnswer);
    }
    return (<button
        onClick={props.clicked}
        className={optionClasses.join(' ')}>
        {props.optionVal}
    </button>);
}

export default Option;