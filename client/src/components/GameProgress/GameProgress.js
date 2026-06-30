import React, { Component } from 'react';
import axios from 'axios';
import { Link } from 'react-router-dom';
import classes from './GameProgress.module.css';

class GameProgress extends Component {
    state = {
        loading: true,
        error: '',
        summary: null,
        attempts: [],
        profiles: [],
        filters: {
            level: '',
            profileId: ''
        }
    };

    componentDidMount() {
        this.fetchProfiles();
        this.fetchProgress();
    }

    fetchProfiles = () => {
        axios.get('/api/profiles')
            .then(response => {
                this.setState({ profiles: response.data || [] });
            })
            .catch(() => {
                this.setState({ profiles: [] });
            });
    };

    fetchProgress = () => {
        const params = {};
        if (this.state.filters.level) {
            params.level = this.state.filters.level;
        }
        if (this.state.filters.profileId) {
            params.profileId = this.state.filters.profileId;
        }

        this.setState({ loading: true, error: '' });

        Promise.all([
            axios.get('/api/game-attempts/summary', { params }),
            axios.get('/api/game-attempts/my', { params: { ...params, limit: 50 } })
        ])
            .then(([summaryResponse, attemptsResponse]) => {
                this.setState({
                    summary: summaryResponse.data,
                    attempts: attemptsResponse.data || [],
                    loading: false,
                    error: ''
                });
            })
            .catch(error => {
                const message = error.response && error.response.data && error.response.data.message
                    ? error.response.data.message
                    : 'Unable to load game progress.';
                this.setState({ loading: false, error: message });
            });
    };

    handleFilterChange = event => {
        const { name, value } = event.target;
        this.setState(prevState => ({
            filters: {
                ...prevState.filters,
                [name]: value
            }
        }), this.fetchProgress);
    };

    formatDate(date) {
        if (!date) {
            return 'Not available';
        }
        return new Date(date).toLocaleString();
    }

    formatDuration(durationMs) {
        const seconds = Math.round((Number(durationMs) || 0) / 1000);
        if (seconds < 60) {
            return `${seconds}s`;
        }
        const minutes = Math.floor(seconds / 60);
        const remainingSeconds = seconds % 60;
        return `${minutes}m ${remainingSeconds}s`;
    }

    renderSummary() {
        const summary = this.state.summary;

        if (!summary) {
            return null;
        }

        return (
            <section className={classes.SummaryGrid}>
                <div className={classes.SummaryCard}>
                    <span>Total attempts</span>
                    <strong>{summary.totalAttempts}</strong>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Average accuracy</span>
                    <strong>{summary.averageAccuracy}%</strong>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Best accuracy</span>
                    <strong>{summary.bestAccuracy}%</strong>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Best score</span>
                    <strong>{summary.bestScore}</strong>
                </div>
            </section>
        );
    }

    renderLevelBreakdown() {
        const summary = this.state.summary;

        if (!summary || !summary.byLevel) {
            return null;
        }

        return (
            <section className={classes.Panel}>
                <h2>Level breakdown</h2>
                <div className={classes.LevelRows}>
                    {summary.byLevel.map(level => (
                        <div className={classes.LevelRow} key={level.level}>
                            <div className={classes.LevelTitle}>Level {level.level}</div>
                            <div className={classes.BarTrack}>
                                <div className={classes.BarFill} style={{ width: `${Math.min(level.averageAccuracy, 100)}%` }}></div>
                            </div>
                            <div className={classes.LevelStats}>
                                {level.attempts} attempts · Avg {level.averageAccuracy}% · Best {level.bestAccuracy}%
                            </div>
                        </div>
                    ))}
                </div>
            </section>
        );
    }

    renderAttempts() {
        if (!this.state.attempts.length) {
            return (
                <section className={classes.EmptyState}>
                    <h2>No game attempts saved yet</h2>
                    <p>Play an emotion game while logged in. Your score, accuracy, and response history will appear here.</p>
                    <Link to="/levels">Open games</Link>
                </section>
            );
        }

        return (
            <section className={classes.Panel}>
                <h2>Recent attempts</h2>
                <div className={classes.AttemptList}>
                    {this.state.attempts.map(attempt => (
                        <article className={classes.AttemptCard} key={attempt._id}>
                            <div>
                                <h3>Level {attempt.level}</h3>
                                <p>
                                    {attempt.profile ? `Profile: ${attempt.profile.name}` : 'Saved to account progress'}
                                </p>
                            </div>
                            <div className={classes.AttemptStats}>
                                <span>{attempt.score} / {attempt.maxScore}</span>
                                <strong>{Math.round(attempt.accuracy)}%</strong>
                            </div>
                            <div className={classes.AttemptMeta}>
                                <span>{this.formatDate(attempt.completedAt)}</span>
                                <span>{this.formatDuration(attempt.durationMs)}</span>
                                <span>{attempt.correctAnswers} of {attempt.totalQuestions} correct</span>
                            </div>
                        </article>
                    ))}
                </div>
            </section>
        );
    }

    render() {
        return (
            <div className={classes.Page}>
                <section className={classes.Header}>
                    <div>
                        <h1>Game Progress</h1>
                        <p>Track saved emotion-learning game attempts by level and child profile.</p>
                    </div>
                    <Link to="/levels">Play games</Link>
                </section>

                <section className={classes.Filters}>
                    <label>
                        Level
                        <select name="level" value={this.state.filters.level} onChange={this.handleFilterChange}>
                            <option value="">All levels</option>
                            <option value="1">Level 1: Images</option>
                            <option value="2">Level 2: Audio</option>
                            <option value="3">Level 3: Video</option>
                        </select>
                    </label>
                    <label>
                        Profile
                        <select name="profileId" value={this.state.filters.profileId} onChange={this.handleFilterChange}>
                            <option value="">All saved attempts</option>
                            <option value="none">Account-only attempts</option>
                            {this.state.profiles.map(profile => (
                                <option key={profile._id} value={profile._id}>{profile.name}</option>
                            ))}
                        </select>
                    </label>
                </section>

                {this.state.loading ? <div className={classes.Panel}>Loading progress...</div> : null}
                {this.state.error ? <div className={classes.ErrorBox}>{this.state.error}</div> : null}

                {!this.state.loading && !this.state.error ? this.renderSummary() : null}
                {!this.state.loading && !this.state.error ? this.renderLevelBreakdown() : null}
                {!this.state.loading && !this.state.error ? this.renderAttempts() : null}
            </div>
        );
    }
}

export default GameProgress;
