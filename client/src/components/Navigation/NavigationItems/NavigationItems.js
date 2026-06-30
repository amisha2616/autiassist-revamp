import React from 'react';
import NavigationItem from './NavigationItem/NavigationItem';
import { AuthContext } from '../../../auth/AuthContext';
import classes from './NavigationItems.module.css';

const navigationItems = props => (
    <AuthContext.Consumer>
        {auth => (
            <div className={classes.NavigationItems}>
                <ul>
                    <NavigationItem link="/levels">Quiz</NavigationItem>
                    <NavigationItem link="/camera">Live Observation</NavigationItem>
                    <NavigationItem link={auth.user ? "/screening/new" : "/questionarie"}>Screening Tool</NavigationItem>
                    {auth.user ? <NavigationItem link="/profiles">Profiles</NavigationItem> : null}
                    <NavigationItem link="/blog">Blog</NavigationItem>

                    {auth.user ? <NavigationItem link="/dashboard">Dashboard</NavigationItem> : null}
                    {auth.user && auth.user.role === 'admin' ? <NavigationItem link="/upload">Admin</NavigationItem> : null}
                    {!auth.user ? <NavigationItem link="/login">Login</NavigationItem> : null}
                    {auth.user ? (
                        <li className={classes.ButtonItem}>
                            <button className={classes.NavButton} onClick={auth.logout}>Logout</button>
                        </li>
                    ) : null}
                </ul>
            </div>
        )}
    </AuthContext.Consumer>
);

export default navigationItems;
