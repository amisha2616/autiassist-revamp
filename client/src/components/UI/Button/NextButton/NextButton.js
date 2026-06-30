import React from 'react';
import classes from './NextButton.module.css';

const nextButton = props => {
    return (
        <button
            onClick={props.clicked}
            className={classes.NextBtn}>
            {props.children}
        </button>
    );
}

export default nextButton;