import React from 'react';
import Question from '../Question/Question';
import Option from '../UI/Option/Option';
import classes from './Questionare.module.css';
import NextButton from '../UI/Button/NextButton/NextButton';
import AudioHero from '../AudioHero/AudioHero';
import ReactAudioPlayer from 'react-audio-player';
import ReactPlayer from 'react-player/lazy';

const Questionare = props => {

    const correct_answer = props.question.correct_answer;
    const shuffled_answers = [...props.question.shuffled_answers];

    const level1Hero = (<img src={props.question.hostedURL} style={{
        height: "200px",
        width: "250px",
    }} id="hostedImg" alt="Question" />);

    const level2Hero = (
        <div className={classes.Level2Hero}>
            <AudioHero />
            <ReactAudioPlayer src={props.question.hostedURL} autoPlay controls />
        </div>);

    const level3Hero = (
        <div className={classes.VideoContainer}>
            <ReactPlayer url={props.question.hostedURL} autoPlay controls />
        </div>
    );

    let hero = (<div>Question File</div>);

    switch (props.level) {
        case 1: hero = level1Hero; break;
        case 2: hero = level2Hero; break;
        case 3: hero = level3Hero; break;
        default: hero = (<div>Question File</div>); break;
    }

    const { questionNo, totalQuestions } = props;

    const percent = ((questionNo + 1) / totalQuestions) * 100;

    return (
        <div className={classes.Questionare}>
            <div className={classes.BarContainer}>
                <div className={classes.ProgressBar} style={{ width: `${percent}%`, backgroundColor: 'red' }}></div>
            </div>
            <div className={classes.ScoreContainer}>{props.score}</div>
            <div className={classes.QuestionContainer}>

                <Question>
                    {hero}
                </Question>
            </div>

            <div className={classes.OptionsContainer}>
                <div className={classes.RowContainer}>
                    <Option
                        showAnswer={props.showAnswer}
                        clicked={() => props.handleAnswer(shuffled_answers[0])}
                        optionVal={shuffled_answers[0]}
                        answer={correct_answer} />

                    <Option
                        showAnswer={props.showAnswer}
                        clicked={() => props.handleAnswer(shuffled_answers[1])}
                        optionVal={shuffled_answers[1]}
                        answer={correct_answer} />
                </div>

                <div className={classes.RowContainer}>
                    <Option
                        showAnswer={props.showAnswer}
                        clicked={() => props.handleAnswer(shuffled_answers[2])}
                        optionVal={shuffled_answers[2]}
                        answer={correct_answer} />

                    <Option
                        showAnswer={props.showAnswer}
                        clicked={() => props.handleAnswer(shuffled_answers[3])}
                        optionVal={shuffled_answers[3]}
                        answer={correct_answer} />
                </div>
            </div>

            {props.showAnswer ?
                <div className={classes.NextButtonContainer} >
                    <NextButton
                        clicked={props.handleNextQuestion}>
                        Next
                        </NextButton>
                </div>
                : <div className={classes.Dummy}></div>
            }
        </div >
    )
};

export default Questionare;