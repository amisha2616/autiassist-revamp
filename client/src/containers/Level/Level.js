import React, { Component } from 'react';
import axios from 'axios';
import classes from './Level.module.css';
import Questionare from '../../components/Questionaire/Questionare';
import LevelCompleted from '../../components/LevelCompleted/LevelCompleted';
import Loader from '../../components/UI/Loader/Loader';

class Level extends Component {

    API_URL = this.props.url;

    state = {
        level: this.props.level,
        questions: [],
        current_question_index: 0,
        score: 0,
        level_completed: false,
        show_answer: false,
    };

    // To shuffle any given array
    shuffleArray = arr => {
        for (let i = arr.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [arr[i], arr[j]] = [arr[j], arr[i]];
        }
        return arr;
    };

    componentDidMount() {

        axios.get(this.API_URL)
            .then(res => res.data)
            .then(data => {
                if(data.length > 0){
                    const questions = data.map(question => ({
                    ...question,
                    // Shuffled options sequence for each question
                    shuffled_answers: [...this.shuffleArray([question.correct_answer, ...question.incorrect_answers])]
                    }));

                    // Set fetched questions in state
                    this.setState({ questions: questions });
                }
                


                
            })
            .catch(err => {
                console.log(err);
                //alert("Unable to connect with Database. Please try again later.", err);
                //alert("unable to connect",err); 
            })
            
    }

    handleAnswer = (answer) => {
        if (!this.state.show_answer) {
            // Check answer and change score
            if (answer === this.state.questions[this.state.current_question_index].correct_answer) {
                this.setState(prevState => {
                    return { score: prevState.score + 10 };
                });
            }
        }

        // Show Answer
        this.setState({ show_answer: true });
    }

    nextQuestionHandler = () => {

        let check_level_completed = false;

        // Check level complete
        if (this.state.current_question_index >= this.state.questions.length - 1) {
            check_level_completed = true;
        }

        // Next question and hide answers
        this.setState(prevState => {
            return {
                current_question_index: prevState.current_question_index + 1,
                show_answer: false,
                level_completed: check_level_completed,
            }
        });
    }

    render() {

        return (
            this.state.level_completed ?
                <LevelCompleted level={this.state.level} score={this.state.score} questionsLength={this.state.questions.length} />
                :
                (
                    this.state.questions.length > 0 ?
                        <div className={classes.Container} >

                            <Questionare
                                score={this.state.score}
                                level={this.state.level}
                                showAnswer={this.state.show_answer}
                                handleAnswer={this.handleAnswer}
                                handleNextQuestion={this.nextQuestionHandler}
                                totalQuestions={this.state.questions.length}
                                questionNo={this.state.current_question_index}
                                question={this.state.questions[this.state.current_question_index]} />

                        </div >
                        : <div className={classes.LoaderWrapper}>
                            <Loader />
                        </div>
                )
        );
    }
}

export default Level;