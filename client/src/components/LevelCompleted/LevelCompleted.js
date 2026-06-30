import React from 'react';
import classes from './LevelCompleted.module.css';
import GoldStar from '../../assets/icons/level-complete/star.svg';
import EmptyStar from '../../assets/icons/level-complete/empty-star.svg';
import Whale from '../../assets/icons/level-complete/whale-animation.svg';
import LevelNoButton from '../UI/Button/LevelNoButton/LevelNoButton';
import { Link } from 'react-router-dom';

const levelCompleted = props => {
    const goldStar = (<img src={GoldStar} alt="Gold Star" />);
    const emptyStar = (<img src={EmptyStar} alt="Empty Star" />);
    const whale = (<img src={Whale} alt="Whale" />);
    const currLevel = '/levels';
    const nextLevel = props.level === 3 ? '/' : `/level${props.level + 1}`;
    const questionsLength = props.questionsLength || 1;
    const maxScore = questionsLength * 10;
    const percentScored = ((props.score / 10) / questionsLength) * 100;

    let saveNotice = null;
    if (props.saveStatus === 'saving') {
        saveNotice = <div className={classes.SaveNotice}>Saving your attempt...</div>;
    } else if (props.saveStatus === 'saved') {
        saveNotice = (
            <div className={classes.SaveNotice}>
                Attempt saved. <Link to="/game-progress">View progress dashboard</Link>
            </div>
        );
    } else if (props.saveStatus === 'not-signed-in') {
        saveNotice = (
            <div className={classes.SaveNotice}>
                {props.saveMessage} <Link to="/login">Log in</Link>
            </div>
        );
    } else if (props.saveStatus === 'error') {
        saveNotice = <div className={classes.SaveNotice}>{props.saveMessage}</div>;
    }

    return (
        <div className={classes.LevelCompleted}>
            <div className={classes.LevelCompleteHeader}>
                Level {props.level} Completed!
            </div>
            <div className={classes.StarsContainer}>
                <div className={classes.Star1}>{percentScored > 0 ? goldStar : emptyStar}</div>
                <div className={classes.Star2}>{percentScored > 30 ? goldStar : emptyStar}</div>
                <div className={classes.Star3}>{percentScored > 60 ? goldStar : emptyStar}</div>
            </div>
            <div className={classes.ScoreContainer}>
                Your Score: {props.score} / {maxScore}
            </div>
            <div className={classes.AccuracyContainer}>
                Accuracy: {Math.round(percentScored)}%
            </div>
            {saveNotice}
            <div className={classes.ButtonsContainer}>
                <Link to={currLevel}>
                    <LevelNoButton url={currLevel}>Replay</LevelNoButton>
                </Link>
                <Link to={nextLevel}>
                    <LevelNoButton url={nextLevel}>Next</LevelNoButton>
                </Link>
            </div>
            <div className={classes.ImageContainer}>
                {whale}
            </div>
        </div>
    );
};

export default levelCompleted;
