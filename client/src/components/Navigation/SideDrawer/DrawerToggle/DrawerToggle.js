import React from 'react';
import classes from './DrawerToggle.module.css';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faBars, faTimes } from '@fortawesome/free-solid-svg-icons';

const drawerToggle = props => {
    let element = "";

    if (props.icon) {
        element =
            <button className={classes.ToggleButton} onClick={() => props.click()}>
                <FontAwesomeIcon icon={faTimes} size="lg" color="white" />
            </button>;
    } else {
        element =
            <button className={classes.ToggleButton} onClick={() => props.click()}>
                <FontAwesomeIcon icon={faBars} size="lg" color="white" />
            </button>;
    }

    return element;
};

export default drawerToggle;
