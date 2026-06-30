import React from 'react';
import NavigationItem from '../NavigationItems/NavigationItem/NavigationItem';
import { AuthContext } from '../../../auth/AuthContext';
import classes from './SideDrawer.module.css';

const sideDrawer = props => {
    let drawerClasses = [classes.SideDrawer];
    if (props.show) {
        drawerClasses = [classes.SideDrawer, classes.Open];
    }

    return (
        <AuthContext.Consumer>
            {auth => (
                <nav className={drawerClasses.join(' ')}>
                    <ul>
                        <NavigationItem link="/levels">Quiz</NavigationItem>
                        <NavigationItem link="/camera">Live Observation</NavigationItem>
                        <NavigationItem link={auth.user ? "/screening/new" : "/questionarie"}>Screening Tool</NavigationItem>
                        {auth.user ? <NavigationItem link="/profiles">Profiles</NavigationItem> : null}
                        {auth.user ? <NavigationItem link="/game-progress">Progress</NavigationItem> : null}
                        {auth.user ? <NavigationItem link="/wellbeing">Wellbeing</NavigationItem> : null}
                        <NavigationItem link="/blog">Blog</NavigationItem>
                        {auth.user ? <NavigationItem link="/dashboard">Dashboard</NavigationItem> : null}
                        {auth.user && auth.user.role === 'admin' ? <NavigationItem link="/upload">Admin Upload</NavigationItem> : null}
                        {!auth.user ? <NavigationItem link="/login">Login</NavigationItem> : null}
                        {auth.user ? (
                            <li>
                                <button className={classes.NavButton} onClick={auth.logout}>Logout</button>
                            </li>
                        ) : null}
                    </ul>
                </nav>
            )}
        </AuthContext.Consumer>
    )
};

export default sideDrawer;
