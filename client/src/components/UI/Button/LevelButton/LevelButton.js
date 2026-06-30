import React from 'react';
import classes from './LevelButton.module.css';

const LevelButton = props =>
    <button className={classes.LevelButton}>
        {props.children}
    </button>;

export default LevelButton;