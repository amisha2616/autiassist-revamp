import classes from './AudioHero.module.css';
import React from 'react';
import CassetteIcon from '../../assets/icons/level2/cassette.svg';

const audioHero = props => {
    return (
        <div className={classes.AudioHero}>
            <div className={classes.ImgContainer}>
                <img alt="Audio Hero" src={CassetteIcon} style={{ height: "130px", width: "250px" }} />
            </div>
        </div>
    )
};

export default audioHero;