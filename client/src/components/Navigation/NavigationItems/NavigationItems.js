import React from 'react';
import NavigationItem from './NavigationItem/NavigationItem';
import classes from './NavigationItems.module.css';


const navigationItems = props =>
    <div className={classes.NavigationItems}>
        <ul>
            <NavigationItem link="/levels">Quiz</NavigationItem>
            <NavigationItem link="/camera">Live Observation</NavigationItem>
            {/* <NavigationItem link="/upload">Upload</NavigationItem> */}
            <NavigationItem link="/questionarie">Screening Tool</NavigationItem>
            <NavigationItem link="/blog">Blog</NavigationItem>
        </ul>
    </div>
    ;

export default navigationItems;