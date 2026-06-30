import React, { Component } from 'react';
import axios from 'axios';
import { Link } from 'react-router-dom';
import classes from './Wellbeing.module.css';

const today = () => new Date().toISOString().slice(0, 10);

class Wellbeing extends Component {
    state = {
        profiles: [],
        logs: [],
        summary: null,
        loading: true,
        submitting: false,
        error: '',
        success: '',
        filters: {
            profileId: ''
        },
        form: {
            profileId: '',
            logDate: today(),
            sleepQuality: '3',
            sensoryOverload: '3',
            communicationEase: '3',
            socialInteraction: '3',
            mood: 'mixed',
            distressEpisodes: '0',
            triggers: '',
            strategies: '',
            notes: ''
        }
    };

    componentDidMount() {
        this.loadInitialData();
    }

    loadInitialData = async () => {
        this.setState({ loading: true, error: '' });

        try {
            const profilesResponse = await axios.get('/api/profiles');
            const profiles = profilesResponse.data || [];
            const firstProfileId = profiles.length ? profiles[0]._id : '';

            this.setState(prevState => ({
                profiles,
                filters: {
                    ...prevState.filters,
                    profileId: firstProfileId
                },
                form: {
                    ...prevState.form,
                    profileId: firstProfileId
                }
            }), this.loadWellbeingData);
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to load profiles.';
            this.setState({ loading: false, error: message });
        }
    };

    loadWellbeingData = async () => {
        const params = {};
        if (this.state.filters.profileId) {
            params.profileId = this.state.filters.profileId;
        }

        this.setState({ loading: true, error: '' });

        try {
            const responses = await Promise.all([
                axios.get('/api/wellbeing-logs/summary', { params }),
                axios.get('/api/wellbeing-logs/my', { params: { ...params, limit: 80 } })
            ]);

            this.setState({
                summary: responses[0].data,
                logs: responses[1].data || [],
                loading: false,
                error: ''
            });
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to load wellbeing logs.';
            this.setState({ loading: false, error: message });
        }
    };

    handleFormChange = event => {
        const { name, value } = event.target;
        this.setState(prevState => ({
            form: {
                ...prevState.form,
                [name]: value
            },
            error: '',
            success: ''
        }));
    };

    handleFilterChange = event => {
        const { value } = event.target;
        this.setState(prevState => ({
            filters: {
                ...prevState.filters,
                profileId: value
            },
            form: {
                ...prevState.form,
                profileId: value || prevState.form.profileId
            }
        }), this.loadWellbeingData);
    };

    submitHandler = async event => {
        event.preventDefault();

        if (!this.state.form.profileId) {
            this.setState({ error: 'Create and select a child profile before saving a wellbeing log.' });
            return;
        }

        this.setState({ submitting: true, error: '', success: '' });

        try {
            await axios.post('/api/wellbeing-logs', this.state.form);
            this.setState(prevState => ({
                submitting: false,
                success: 'Wellbeing log saved.',
                form: {
                    ...prevState.form,
                    logDate: today(),
                    sleepQuality: '3',
                    sensoryOverload: '3',
                    communicationEase: '3',
                    socialInteraction: '3',
                    mood: 'mixed',
                    distressEpisodes: '0',
                    triggers: '',
                    strategies: '',
                    notes: ''
                }
            }), this.loadWellbeingData);
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to save wellbeing log.';
            this.setState({ submitting: false, error: message });
        }
    };

    deleteLog = async logId => {
        const confirmed = window.confirm('Delete this wellbeing log?');
        if (!confirmed) {
            return;
        }

        try {
            await axios.delete(`/api/wellbeing-logs/${logId}`);
            this.loadWellbeingData();
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to delete wellbeing log.';
            this.setState({ error: message });
        }
    };

    formatDate(date) {
        if (!date) {
            return 'Not available';
        }
        return new Date(date).toLocaleDateString();
    }

    formatMood(mood) {
        return String(mood || 'mixed').replace(/_/g, ' ');
    }

    renderScoreLabel(value) {
        const score = Number(value);
        if (score >= 80) {
            return 'Stable';
        }
        if (score >= 60) {
            return 'Moderate';
        }
        if (score > 0) {
            return 'Needs attention';
        }
        return 'No data';
    }

    renderSummary() {
        const summary = this.state.summary;
        if (!summary) {
            return null;
        }

        return (
            <section className={classes.SummaryGrid}>
                <div className={classes.SummaryCard}>
                    <span>Total logs</span>
                    <strong>{summary.totalLogs}</strong>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Average wellbeing</span>
                    <strong>{summary.averageOverallScore}%</strong>
                    <small>{this.renderScoreLabel(summary.averageOverallScore)}</small>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Common mood</span>
                    <strong>{this.formatMood(summary.mostCommonMood)}</strong>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Avg sensory overload</span>
                    <strong>{summary.averageSensoryOverload}/5</strong>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Avg communication ease</span>
                    <strong>{summary.averageCommunicationEase}/5</strong>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Avg distress episodes</span>
                    <strong>{summary.averageDistressEpisodes}</strong>
                </div>
            </section>
        );
    }

    renderTrend() {
        const summary = this.state.summary;
        const trend = summary && summary.trend ? summary.trend.slice(-14) : [];

        if (!trend.length) {
            return null;
        }

        return (
            <section className={classes.Panel}>
                <h2>Recent wellbeing trend</h2>
                <p className={classes.HelperText}>Higher bars mean a more settled day based on sleep, sensory load, communication, social interaction, and distress frequency.</p>
                <div className={classes.TrendList}>
                    {trend.map(item => (
                        <div className={classes.TrendRow} key={item.id}>
                            <span>{this.formatDate(item.logDate)}</span>
                            <div className={classes.BarTrack}>
                                <div className={classes.BarFill} style={{ width: `${Math.max(4, Math.min(Number(item.overallScore) || 0, 100))}%` }}></div>
                            </div>
                            <strong>{item.overallScore}%</strong>
                        </div>
                    ))}
                </div>
            </section>
        );
    }

    renderForm() {
        return (
            <form className={classes.Card} onSubmit={this.submitHandler}>
                <h2>Add daily log</h2>
                <p className={classes.HelperText}>Use this to record patterns. It is for caregiver tracking, not diagnosis.</p>

                {this.state.error ? <div className={classes.Error}>{this.state.error}</div> : null}
                {this.state.success ? <div className={classes.Success}>{this.state.success}</div> : null}

                <label>Child profile</label>
                <select name="profileId" value={this.state.form.profileId} onChange={this.handleFormChange} required>
                    <option value="">Select profile</option>
                    {this.state.profiles.map(profile => (
                        <option key={profile._id} value={profile._id}>{profile.name}</option>
                    ))}
                </select>

                <label>Date</label>
                <input name="logDate" type="date" value={this.state.form.logDate} onChange={this.handleFormChange} required />

                <label>Sleep quality</label>
                <select name="sleepQuality" value={this.state.form.sleepQuality} onChange={this.handleFormChange}>
                    <option value="1">1 - Very poor</option>
                    <option value="2">2 - Poor</option>
                    <option value="3">3 - Average</option>
                    <option value="4">4 - Good</option>
                    <option value="5">5 - Very good</option>
                </select>

                <label>Sensory overload</label>
                <select name="sensoryOverload" value={this.state.form.sensoryOverload} onChange={this.handleFormChange}>
                    <option value="1">1 - Very low</option>
                    <option value="2">2 - Low</option>
                    <option value="3">3 - Moderate</option>
                    <option value="4">4 - High</option>
                    <option value="5">5 - Very high</option>
                </select>

                <label>Communication ease</label>
                <select name="communicationEase" value={this.state.form.communicationEase} onChange={this.handleFormChange}>
                    <option value="1">1 - Very difficult</option>
                    <option value="2">2 - Difficult</option>
                    <option value="3">3 - Mixed</option>
                    <option value="4">4 - Good</option>
                    <option value="5">5 - Very good</option>
                </select>

                <label>Social interaction</label>
                <select name="socialInteraction" value={this.state.form.socialInteraction} onChange={this.handleFormChange}>
                    <option value="1">1 - Avoidant or distressed</option>
                    <option value="2">2 - Limited</option>
                    <option value="3">3 - Mixed</option>
                    <option value="4">4 - Engaged</option>
                    <option value="5">5 - Very engaged</option>
                </select>

                <label>Mood</label>
                <select name="mood" value={this.state.form.mood} onChange={this.handleFormChange}>
                    <option value="calm">Calm</option>
                    <option value="happy">Happy</option>
                    <option value="tired">Tired</option>
                    <option value="anxious">Anxious</option>
                    <option value="frustrated">Frustrated</option>
                    <option value="overwhelmed">Overwhelmed</option>
                    <option value="mixed">Mixed</option>
                </select>

                <label>Distress episodes</label>
                <input name="distressEpisodes" type="number" min="0" max="20" value={this.state.form.distressEpisodes} onChange={this.handleFormChange} />

                <label>Possible triggers</label>
                <input name="triggers" value={this.state.form.triggers} onChange={this.handleFormChange} placeholder="Example: loud noise, crowd, routine change" />

                <label>Helpful strategies</label>
                <input name="strategies" value={this.state.form.strategies} onChange={this.handleFormChange} placeholder="Example: quiet space, visual schedule, deep pressure" />

                <label>Notes</label>
                <textarea name="notes" rows="4" value={this.state.form.notes} onChange={this.handleFormChange} placeholder="Short caregiver note for this day." />

                <button type="submit" disabled={this.state.submitting || !this.state.profiles.length}>
                    {this.state.submitting ? 'Saving...' : 'Save wellbeing log'}
                </button>
            </form>
        );
    }

    renderLogs() {
        if (this.state.loading) {
            return <section className={classes.Panel}>Loading wellbeing logs...</section>;
        }

        if (!this.state.logs.length) {
            return (
                <section className={classes.EmptyState}>
                    <h2>No wellbeing logs yet</h2>
                    <p>Add a daily log to start building a useful progress history.</p>
                </section>
            );
        }

        return (
            <section className={classes.Panel}>
                <h2>Recent logs</h2>
                <div className={classes.LogList}>
                    {this.state.logs.map(log => (
                        <article className={classes.LogCard} key={log._id}>
                            <div className={classes.LogTop}>
                                <div>
                                    <h3>{log.profile && log.profile.name ? log.profile.name : 'Profile'}</h3>
                                    <p>{this.formatDate(log.logDate)} · Mood: {this.formatMood(log.mood)}</p>
                                </div>
                                <div className={classes.ScorePill}>{log.overallScore}%</div>
                            </div>
                            <div className={classes.MetricGrid}>
                                <span>Sleep {log.sleepQuality}/5</span>
                                <span>Sensory {log.sensoryOverload}/5</span>
                                <span>Communication {log.communicationEase}/5</span>
                                <span>Social {log.socialInteraction}/5</span>
                                <span>Distress {log.distressEpisodes}</span>
                            </div>
                            {log.triggers && log.triggers.length ? <p><strong>Triggers:</strong> {log.triggers.join(', ')}</p> : null}
                            {log.strategies && log.strategies.length ? <p><strong>Strategies:</strong> {log.strategies.join(', ')}</p> : null}
                            {log.notes ? <p className={classes.Notes}>{log.notes}</p> : null}
                            <button type="button" className={classes.DeleteButton} onClick={() => this.deleteLog(log._id)}>Delete</button>
                        </article>
                    ))}
                </div>
            </section>
        );
    }

    render() {
        const hasProfiles = this.state.profiles.length > 0;

        return (
            <div className={classes.Page}>
                <section className={classes.Header}>
                    <div>
                        <h1>Wellbeing Tracker</h1>
                        <p>Save caregiver notes about sleep, sensory load, communication, mood, and daily supports.</p>
                    </div>
                    <Link to="/profiles">Manage profiles</Link>
                </section>

                {!hasProfiles && !this.state.loading ? (
                    <section className={classes.EmptyState}>
                        <h2>Create a child profile first</h2>
                        <p>Wellbeing logs are linked to child profiles so they can be reviewed with screening and game progress later.</p>
                        <Link to="/profiles">Add profile</Link>
                    </section>
                ) : null}

                {hasProfiles ? (
                    <section className={classes.Filters}>
                        <label>
                            View logs for
                            <select value={this.state.filters.profileId} onChange={this.handleFilterChange}>
                                <option value="">All profiles</option>
                                {this.state.profiles.map(profile => (
                                    <option key={profile._id} value={profile._id}>{profile.name}</option>
                                ))}
                            </select>
                        </label>
                    </section>
                ) : null}

                {hasProfiles ? this.renderSummary() : null}

                <section className={classes.Layout}>
                    {this.renderForm()}
                    <div>
                        {hasProfiles ? this.renderTrend() : null}
                        {hasProfiles ? this.renderLogs() : null}
                    </div>
                </section>
            </div>
        );
    }
}

export default Wellbeing;
