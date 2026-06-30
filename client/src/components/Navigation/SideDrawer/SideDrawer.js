import React from 'react';
import NavigationItem from '../NavigationItems/NavigationItem/NavigationItem';
import classes from './SideDrawer.module.css';

const sideDrawer = props => {
    let drawerClasses = [classes.SideDrawer];
    if (props.show) {
        drawerClasses = [classes.SideDrawer, classes.Open];
    }
    return (
        <nav className={drawerClasses.join(' ')}>
            <ul>
                <NavigationItem link="/levels">Quiz</NavigationItem>
                <NavigationItem link="/camera">Camera</NavigationItem>
                <NavigationItem link="/upload">Upload</NavigationItem>
                <NavigationItem link="/credits">Credits</NavigationItem>
            </ul>
        </nav>
    )
};

export default sideDrawer;