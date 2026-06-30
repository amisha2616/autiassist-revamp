import React, { Component } from 'react';
import axios from 'axios';
import { Link } from 'react-router-dom';
import classes from './Screening.module.css';

class Screening extends Component {
    state = {
        templates: null,
        profiles: [],
        history: [],
        assessmentType: 'child',
        profileId: '',
        answers: {},
        result: null,
        loading: true,
        submitting: false,
        error: ''
    };

    componentDidMount() {
        this.loadData();
    }

    loadData = async () => {
        this.setState({ loading: true, error: '' });

        try {
            const [templatesResponse, profilesResponse, historyResponse] = await Promise.all([
                axios.get('/api/assessment-sessions/templates'),
                axios.get('/api/profiles'),
                axios.get('/api/assessment-sessions/my')
            ]);

            const firstProfile = profilesResponse.data[0] ? profilesResponse.data[0]._id : '';

            this.setState({
                templates: templatesResponse.data,
                profiles: profilesResponse.data,
                history: historyResponse.data,
                profileId: firstProfile,
                loading: false
            });
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to load screening data.';
            this.setState({ error: message, loading: false });
        }
    };

    changeType = event => {
        const assessmentType = event.target.value;
        this.setState({ assessmentType, answers: {}, result: null, error: '' });
    };

    changeProfile = event => {
        this.setState({ profileId: event.target.value, result: null, error: '' });
    };

    selectAnswer = (questionId, answer) => {
        this.setState(prevState => ({
            answers: {
                ...prevState.answers,
                [questionId]: answer
            },
            error: ''
        }));
    };

    submitHandler = async event => {
        event.preventDefault();

        const template = this.state.templates[this.state.assessmentType];
        const missing = template.questions.some(question => !this.state.answers[question.id]);

        if (missing) {
            this.setState({ error: 'Please answer all questions before submitting.' });
            return;
        }

        if (this.state.assessmentType === 'child' && !this.state.profileId) {
            this.setState({ error: 'Create or select a child profile before submitting.' });
            return;
        }

        this.setState({ submitting: true, error: '', result: null });

        try {
            const response = await axios.post('/api/assessment-sessions', {
                assessmentType: this.state.assessmentType,
                profileId: this.state.assessmentType === 'child' ? this.state.profileId : null,
                responses: template.questions.map(question => ({
                    questionId: question.id,
                    answer: this.state.answers[question.id]
                }))
            });

            const historyResponse = await axios.get('/api/assessment-sessions/my');

            this.setState({
                result: response.data,
                history: historyResponse.data,
                submitting: false
            });
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to save screening result.';
            this.setState({ error: message, submitting: false });
        }
    };

    resetForm = () => {
        this.setState({ answers: {}, result: null, error: '' });
        window.scrollTo(0, 0);
    };

    bandClass(band) {
        if (band === 'high') {
            return classes.High;
        }
        if (band === 'moderate') {
            return classes.Moderate;
        }
        return classes.Low;
    }

    render() {
        const template = this.state.templates ? this.state.templates[this.state.assessmentType] : null;
        const completedCount = template
            ? template.questions.filter(question => this.state.answers[question.id]).length
            : 0;

        return (
            <div className={classes.Page}>
                <section className={classes.Header}>
                    <h1>Saved screening support</h1>
                    <p>Complete a non-diagnostic questionnaire and save the result to your account history.</p>
                </section>

                {this.state.loading ? <div className={classes.Notice}>Loading screening module...</div> : null}
                {this.state.error ? <div className={classes.Error}>{this.state.error}</div> : null}

                {!this.state.loading && template ? (
                    <section className={classes.Layout}>
                        <form className={classes.Card} onSubmit={this.submitHandler}>
                            <div className={classes.TopControls}>
                                <label>
                                    Screening type
                                    <select value={this.state.assessmentType} onChange={this.changeType}>
                                        <option value="child">Child screening</option>
                                        <option value="adult">Adult self-check</option>
                                    </select>
                                </label>

                                {this.state.assessmentType === 'child' ? (
                                    <label>
                                        Child profile
                                        <select value={this.state.profileId} onChange={this.changeProfile}>
                                            <option value="">Select profile</option>
                                            {this.state.profiles.map(profile => (
                                                <option key={profile._id} value={profile._id}>{profile.name}</option>
                                            ))}
                                        </select>
                                    </label>
                                ) : null}
                            </div>

                            {this.state.assessmentType === 'child' && this.state.profiles.length === 0 ? (
                                <div className={classes.Warning}>
                                    Create a child profile before saving child screening results. <Link to="/profiles">Add profile</Link>
                                </div>
                            ) : null}

                            <div className={classes.TemplateHeader}>
                                <h2>{template.title}</h2>
                                <p>{completedCount}/{template.questions.length} answered</p>
                            </div>

                            <p className={classes.Disclaimer}>{template.disclaimer}</p>

                            {template.questions.map((question, index) => (
                                <article key={question.id} className={classes.Question}>
                                    <h3>{index + 1}. {question.text}</h3>
                                    <div className={classes.Options}>
                                        {question.options.map(option => (
                                            <button
                                                key={option}
                                                type="button"
                                                className={this.state.answers[question.id] === option ? classes.Selected : ''}
                                                onClick={() => this.selectAnswer(question.id, option)}
                                            >
                                                {option}
                                            </button>
                                        ))}
                                    </div>
                                </article>
                            ))}

                            <button className={classes.SubmitButton} type="submit" disabled={this.state.submitting}>
                                {this.state.submitting ? 'Saving result...' : 'Save screening result'}
                            </button>
                        </form>

                        <aside className={classes.SidePanel}>
                            {this.state.result ? (
                                <div className={classes.ResultCard}>
                                    <span className={`${classes.Band} ${this.bandClass(this.state.result.band)}`}>
                                        {this.state.result.band} likelihood indicators
                                    </span>
                                    <h2>Score: {this.state.result.score}/{this.state.result.maxScore}</h2>
                                    <p>{this.state.result.recommendation}</p>
                                    <p className={classes.SmallText}>{this.state.result.disclaimer}</p>
                                    <button type="button" onClick={this.resetForm}>Start another screening</button>
                                </div>
                            ) : (
                                <div className={classes.ResultCard}>
                                    <h2>Result will appear here</h2>
                                    <p>After submission, the score band and recommendation will be saved to your history.</p>
                                </div>
                            )}

                            <div className={classes.HistoryCard}>
                                <h2>Recent history</h2>
                                {this.state.history.length === 0 ? <p>No saved screenings yet.</p> : null}

                                {this.state.history.slice(0, 6).map(session => (
                                    <div key={session._id} className={classes.HistoryItem}>
                                        <strong>{session.assessmentType === 'child' ? 'Child screening' : 'Adult self-check'}</strong>
                                        <span className={`${classes.HistoryBand} ${this.bandClass(session.band)}`}>{session.band}</span>
                                        <p>{session.profile ? `Profile: ${session.profile.name}` : 'No child profile linked'}</p>
                                        <p>Score: {session.score}/{session.maxScore}</p>
                                        <small>{new Date(session.createdAt).toLocaleString()}</small>
                                    </div>
                                ))}
                            </div>
                        </aside>
                    </section>
                ) : null}
            </div>
        );
    }
}

export default Screening;
