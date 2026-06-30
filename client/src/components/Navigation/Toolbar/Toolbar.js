import React from 'react';
import NavigationItems from '../NavigationItems/NavigationItems';
import DrawerToggle from '../SideDrawer/DrawerToggle/DrawerToggle';
import classes from './Toolbar.module.css';

const toolbar = props => {
    return (
        <div className={classes.Toolbar}>
            <nav className={classes.Toolbar__Navigation}>
                <div>
                    <DrawerToggle icon={props.show} click={props.drawerClickHandler} />
                </div>
                <div className={classes.Toolbar__Logo}><a href="/">AUTISMO</a></div>
                <div className={classes.Spacer}></div>
                <NavigationItems />
            </nav>
        </div>
    )
}


export default toolbar;