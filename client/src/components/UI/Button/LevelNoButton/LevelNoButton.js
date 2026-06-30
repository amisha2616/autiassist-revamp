import React from 'react';
import classes from './LevelNoButton.module.css';

const levelNoButton = props =>
    <button className={classes.LevelNoBtn}>
        {props.children}
    </button>;

export default levelNoButton;