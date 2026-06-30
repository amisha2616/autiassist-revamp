import React, { Component } from 'react';
import axios from 'axios';
import classes from './Level.module.css';
import Questionare from '../../components/Questionaire/Questionare';
import LevelCompleted from '../../components/LevelCompleted/LevelCompleted';
import Loader from '../../components/UI/Loader/Loader';
import { AuthContext } from '../../auth/AuthContext';

class Level extends Component {

    static contextType = AuthContext;

    API_URL = this.props.url;

    state = {
        level: this.props.level,
        questions: [],
        current_question_index: 0,
        score: 0,
        level_completed: false,
        show_answer: false,
        status: 'loading',
        error: '',
        profiles: [],
        profilesRequested: false,
        selectedProfile: '',
        profileLoadError: '',
        startedAt: new Date().toISOString(),
        questionStartedAt: Date.now(),
        responses: [],
        saveStatus: 'idle',
        saveMessage: '',
        attemptSaved: null
    };

    shuffleArray = arr => {
        const cloned = [...arr];
        for (let i = cloned.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [cloned[i], cloned[j]] = [cloned[j], cloned[i]];
        }
        return cloned;
    };

    componentDidMount() {
        this.fetchQuestions();
        this.fetchProfilesIfLoggedIn();
    }

    componentDidUpdate() {
        this.fetchProfilesIfLoggedIn();
    }

    fetchQuestions = () => {
        axios.get(this.API_URL)
            .then(res => res.data)
            .then(data => {
                if (data.length > 0) {
                    const questions = data.map(question => ({
                        ...question,
                        shuffled_answers: this.shuffleArray([question.correct_answer, ...(question.incorrect_answers || [])])
                    }));

                    this.setState({ questions, status: 'ready', error: '' });
                } else {
                    this.setState({ status: 'empty', error: '' });
                }
            })
            .catch(err => {
                const message = err.response && err.response.data && err.response.data.message
                    ? err.response.data.message
                    : 'Unable to load questions. Please try again later.';
                this.setState({ status: 'error', error: message });
            });
    };

    fetchProfilesIfLoggedIn = () => {
        const auth = this.context || {};

        if (!auth.user || this.state.profilesRequested) {
            return;
        }

        this.setState({ profilesRequested: true });

        axios.get('/api/profiles')
            .then(response => {
                this.setState({ profiles: response.data || [], profileLoadError: '' });
            })
            .catch(() => {
                this.setState({ profileLoadError: 'Could not load profiles. The attempt can still be saved to your account.' });
            });
    };

    handleProfileChange = event => {
        this.setState({ selectedProfile: event.target.value });
    };

    handleAnswer = answer => {
        if (this.state.show_answer) {
            return;
        }

        const question = this.state.questions[this.state.current_question_index];
        const isCorrect = answer === question.correct_answer;
        const now = Date.now();

        const response = {
            question: question._id,
            questionText: question.question || '',
            mediaType: question.mediaType || (this.state.level === 1 ? 'image' : this.state.level === 2 ? 'audio' : 'video'),
            selectedAnswer: answer,
            correctAnswer: question.correct_answer,
            isCorrect,
            responseTimeMs: Math.max(0, now - this.state.questionStartedAt)
        };

        this.setState(prevState => ({
            score: prevState.score + (isCorrect ? 10 : 0),
            show_answer: true,
            responses: prevState.responses.concat(response)
        }));
    };

    nextQuestionHandler = () => {
        const isLastQuestion = this.state.current_question_index >= this.state.questions.length - 1;

        if (isLastQuestion) {
            this.setState(prevState => ({
                current_question_index: prevState.current_question_index + 1,
                show_answer: false,
                level_completed: true
            }), this.saveGameAttempt);
            return;
        }

        this.setState(prevState => ({
            current_question_index: prevState.current_question_index + 1,
            show_answer: false,
            questionStartedAt: Date.now()
        }));
    };

    saveGameAttempt = () => {
        const auth = this.context || {};

        if (!auth.user) {
            this.setState({
                saveStatus: 'not-signed-in',
                saveMessage: 'Sign in before playing to save scores and progress history.'
            });
            return;
        }

        if (this.state.saveStatus === 'saving' || this.state.saveStatus === 'saved') {
            return;
        }

        const completedAt = new Date();
        const startedAt = new Date(this.state.startedAt);
        const correctAnswers = this.state.responses.filter(response => response.isCorrect).length;
        const totalQuestions = this.state.questions.length;

        const payload = {
            profile: this.state.selectedProfile || null,
            level: this.state.level,
            score: this.state.score,
            maxScore: totalQuestions * 10,
            totalQuestions,
            correctAnswers,
            startedAt: startedAt.toISOString(),
            completedAt: completedAt.toISOString(),
            durationMs: Math.max(0, completedAt.getTime() - startedAt.getTime()),
            responses: this.state.responses
        };

        this.setState({ saveStatus: 'saving', saveMessage: 'Saving your attempt...' });

        axios.post('/api/game-attempts', payload)
            .then(response => {
                this.setState({
                    saveStatus: 'saved',
                    saveMessage: 'Attempt saved to your progress dashboard.',
                    attemptSaved: response.data
                });
            })
            .catch(error => {
                const message = error.response && error.response.data && error.response.data.message
                    ? error.response.data.message
                    : 'Attempt completed, but it could not be saved right now.';
                this.setState({ saveStatus: 'error', saveMessage: message });
            });
    };

    renderProfileSelector() {
        const auth = this.context || {};

        if (!auth.user) {
            return (
                <div className={classes.AttemptNotice}>
                    Playing as guest. Log in to save your score and progress history.
                </div>
            );
        }

        return (
            <div className={classes.ProfileSelector}>
                <label htmlFor="profile-select">Save attempt under</label>
                <select id="profile-select" value={this.state.selectedProfile} onChange={this.handleProfileChange}>
                    <option value="">My account progress</option>
                    {this.state.profiles.map(profile => (
                        <option key={profile._id} value={profile._id}>
                            {profile.name}{profile.nickname ? ` (${profile.nickname})` : ''}
                        </option>
                    ))}
                </select>
                {this.state.profileLoadError ? <p>{this.state.profileLoadError}</p> : null}
            </div>
        );
    }

    render() {
        if (this.state.level_completed) {
            return (
                <LevelCompleted
                    level={this.state.level}
                    score={this.state.score}
                    questionsLength={this.state.questions.length}
                    saveStatus={this.state.saveStatus}
                    saveMessage={this.state.saveMessage}
                    attemptSaved={this.state.attemptSaved}
                />
            );
        }

        if (this.state.status === 'error') {
            return <div className={classes.MessageBox}>{this.state.error}</div>;
        }

        if (this.state.status === 'empty') {
            return <div className={classes.MessageBox}>No questions are available for this level yet.</div>;
        }

        return (
            this.state.questions.length > 0 ?
                <div className={classes.Container}>
                    {this.renderProfileSelector()}

                    <Questionare
                        score={this.state.score}
                        level={this.state.level}
                        showAnswer={this.state.show_answer}
                        handleAnswer={this.handleAnswer}
                        handleNextQuestion={this.nextQuestionHandler}
                        totalQuestions={this.state.questions.length}
                        questionNo={this.state.current_question_index}
                        question={this.state.questions[this.state.current_question_index]} />
                </div>
                : <div className={classes.LoaderWrapper}>
                    <Loader />
                </div>
        );
    }
}

export default Level;
