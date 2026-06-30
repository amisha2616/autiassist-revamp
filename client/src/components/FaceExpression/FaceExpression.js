import React from 'react';
import EmotionDetection from '../../containers/EmotionDetection/EmotionDetection';
import FooterSection from '../FooterSection/FooterSection';
import classes from './FaceExpression.module.css';

const faceExpression = props => {
    return (
        <div className={classes.Container}>
            <div className={classes.Center}>
                <div className={classes.Header}>
                    Recognizing Facial Expressions
            </div>
            </div>
            <EmotionDetection />
            <FooterSection />
        </div>
    )
}

export default faceExpression;