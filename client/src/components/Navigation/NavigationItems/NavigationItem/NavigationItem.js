import React from 'react';
import { NavLink } from 'react-router-dom';
import classes from './NavigationItem.module.css';

const navigationItem = props =>
    <li>
        <NavLink to={props.link} className={classes.Normal} activeClassName={classes.Selected} exact>
            {props.children}
        </NavLink>
    </li>
    ;

export default navigationItem;