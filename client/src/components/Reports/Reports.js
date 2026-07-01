import React, { Component } from 'react';
import axios from 'axios';
import { Link } from 'react-router-dom';
import classes from './Reports.module.css';

class Reports extends Component {
    state = {
        profiles: [],
        reports: [],
        selectedProfileId: '',
        overview: null,
        selectedReport: null,
        fromDate: '',
        toDate: '',
        loading: true,
        generating: false,
        error: '',
        success: ''
    };

    componentDidMount() {
        this.loadInitialData();
    }

    loadInitialData = async () => {
        this.setState({ loading: true, error: '', success: '' });

        try {
            const profilesResponse = await axios.get('/api/profiles');
            const profiles = profilesResponse.data || [];
            const firstProfileId = profiles.length ? profiles[0]._id : '';

            this.setState({
                profiles,
                selectedProfileId: firstProfileId,
                loading: false
            }, () => {
                if (firstProfileId) {
                    this.loadReportData();
                }
            });
        } catch (error) {
            const message = this.getErrorMessage(error, 'Unable to load profiles.');
            this.setState({ loading: false, error: message });
        }
    };

    getErrorMessage(error, fallback) {
        if (error.response && error.response.data && error.response.data.message) {
            return error.response.data.message;
        }
        return fallback;
    }

    loadReportData = async () => {
        if (!this.state.selectedProfileId) {
            return;
        }

        const params = {
            profileId: this.state.selectedProfileId
        };

        if (this.state.fromDate) {
            params.fromDate = this.state.fromDate;
        }

        if (this.state.toDate) {
            params.toDate = this.state.toDate;
        }

        this.setState({ loading: true, error: '', success: '', selectedReport: null });

        try {
            const responses = await Promise.all([
                axios.get('/api/reports/overview', { params }),
                axios.get('/api/reports/my', { params: { profileId: this.state.selectedProfileId, limit: 30 } })
            ]);

            this.setState({
                overview: responses[0].data,
                reports: responses[1].data || [],
                loading: false
            });
        } catch (error) {
            const message = this.getErrorMessage(error, 'Unable to load report data.');
            this.setState({ loading: false, error: message });
        }
    };

    inputHandler = event => {
        const name = event.target.name;
        const value = event.target.value;
        this.setState({ [name]: value, error: '', success: '' });
    };

    profileChangeHandler = event => {
        this.setState({ selectedProfileId: event.target.value, error: '', success: '' }, this.loadReportData);
    };

    filterSubmitHandler = event => {
        event.preventDefault();
        this.loadReportData();
    };

    clearFilters = () => {
        this.setState({ fromDate: '', toDate: '' }, this.loadReportData);
    };

    generateReport = async () => {
        if (!this.state.selectedProfileId) {
            this.setState({ error: 'Create and select a child profile before generating a report.' });
            return;
        }

        this.setState({ generating: true, error: '', success: '' });

        try {
            const payload = {
                profileId: this.state.selectedProfileId,
                fromDate: this.state.fromDate,
                toDate: this.state.toDate
            };
            const response = await axios.post('/api/reports/generate', payload);

            this.setState({
                generating: false,
                selectedReport: response.data,
                success: 'Report generated and saved.'
            }, this.loadSavedReports);
        } catch (error) {
            const message = this.getErrorMessage(error, 'Unable to generate report.');
            this.setState({ generating: false, error: message });
        }
    };

    loadSavedReports = async () => {
        if (!this.state.selectedProfileId) {
            return;
        }

        try {
            const response = await axios.get('/api/reports/my', {
                params: {
                    profileId: this.state.selectedProfileId,
                    limit: 30
                }
            });
            this.setState({ reports: response.data || [] });
        } catch (error) {
            this.setState({ error: this.getErrorMessage(error, 'Unable to refresh saved reports.') });
        }
    };

    viewReport = async reportId => {
        try {
            const response = await axios.get(`/api/reports/${reportId}`);
            this.setState({ selectedReport: response.data, success: 'Showing saved report snapshot.', error: '' });
        } catch (error) {
            this.setState({ error: this.getErrorMessage(error, 'Unable to load saved report.') });
        }
    };

    deleteReport = async reportId => {
        const confirmed = window.confirm('Delete this saved report?');
        if (!confirmed) {
            return;
        }

        try {
            await axios.delete(`/api/reports/${reportId}`);
            this.setState({ selectedReport: null, success: 'Report deleted.', error: '' }, this.loadSavedReports);
        } catch (error) {
            this.setState({ error: this.getErrorMessage(error, 'Unable to delete report.') });
        }
    };

    printReport = () => {
        window.print();
    };

    activeSnapshot() {
        if (this.state.selectedReport && this.state.selectedReport.snapshot) {
            return this.state.selectedReport.snapshot;
        }
        return this.state.overview;
    }

    formatDate(date) {
        if (!date) {
            return 'Not available';
        }
        return new Date(date).toLocaleDateString();
    }

    formatDateTime(date) {
        if (!date) {
            return 'Not available';
        }
        return new Date(date).toLocaleString();
    }

    formatBand(band) {
        if (!band || band === 'not_available') {
            return 'No screening yet';
        }
        return String(band).replace(/_/g, ' ');
    }

    formatMood(mood) {
        if (!mood || mood === 'not_available') {
            return 'No data';
        }
        return String(mood).replace(/_/g, ' ');
    }

    scoreLabel(value, suffix) {
        const number = Number(value);
        if (!Number.isFinite(number) || number === 0) {
            return 'No data';
        }
        return `${number}${suffix || ''}`;
    }

    bandClassName(band) {
        const value = String(band || '').toLowerCase();
        if (value === 'high') {
            return [classes.Band, classes.BandHigh].join(' ');
        }
        if (value === 'moderate') {
            return [classes.Band, classes.BandModerate].join(' ');
        }
        if (value === 'low') {
            return [classes.Band, classes.BandLow].join(' ');
        }
        return classes.Band;
    }

    renderControls() {
        return (
            <section className={[classes.Controls, classes.NoPrint].join(' ')}>
                <div className={classes.ControlGrid}>
                    <label>
                        Child profile
                        <select name="selectedProfileId" value={this.state.selectedProfileId} onChange={this.profileChangeHandler}>
                            {this.state.profiles.map(profile => (
                                <option value={profile._id} key={profile._id}>{profile.name}{profile.nickname ? ` (${profile.nickname})` : ''}</option>
                            ))}
                        </select>
                    </label>

                    <form className={classes.FilterForm} onSubmit={this.filterSubmitHandler}>
                        <label>
                            From
                            <input type="date" name="fromDate" value={this.state.fromDate} onChange={this.inputHandler} />
                        </label>
                        <label>
                            To
                            <input type="date" name="toDate" value={this.state.toDate} onChange={this.inputHandler} />
                        </label>
                        <div className={classes.FilterButtons}>
                            <button type="submit">Apply</button>
                            <button type="button" onClick={this.clearFilters}>Clear</button>
                        </div>
                    </form>
                </div>

                <div className={classes.ActionRow}>
                    <button type="button" onClick={this.generateReport} disabled={this.state.generating}>
                        {this.state.generating ? 'Generating...' : 'Generate saved report'}
                    </button>
                    <button type="button" onClick={this.printReport}>Print or save as PDF</button>
                    <Link to="/dashboard">Back to dashboard</Link>
                </div>
            </section>
        );
    }

    renderSummaryCards(snapshot) {
        const assessment = snapshot.assessmentSummary || {};
        const latestAssessment = assessment.latest;
        const game = snapshot.gameSummary || {};
        const wellbeing = snapshot.wellbeingSummary || {};

        return (
            <section className={classes.SummaryGrid}>
                <div className={classes.SummaryCard}>
                    <span>Latest screening</span>
                    <strong className={this.bandClassName(latestAssessment ? latestAssessment.band : '')}>{this.formatBand(latestAssessment ? latestAssessment.band : '')}</strong>
                    <small>{latestAssessment ? `${latestAssessment.score}/${latestAssessment.maxScore}` : 'No saved screening'}</small>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Game attempts</span>
                    <strong>{game.totalAttempts || 0}</strong>
                    <small>Average accuracy: {this.scoreLabel(game.averageAccuracy, '%')}</small>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Wellbeing logs</span>
                    <strong>{wellbeing.totalLogs || 0}</strong>
                    <small>Average score: {this.scoreLabel(wellbeing.averageOverallScore, '%')}</small>
                </div>
                <div className={classes.SummaryCard}>
                    <span>Report generated</span>
                    <strong>{this.formatDate(snapshot.generatedAt)}</strong>
                    <small>{snapshot.generatedBy ? `By ${snapshot.generatedBy.name}` : 'Current preview'}</small>
                </div>
            </section>
        );
    }

    renderProfileSection(snapshot) {
        const profile = snapshot.profile || {};

        return (
            <section className={classes.ReportSection}>
                <h2>Profile details</h2>
                <div className={classes.DetailGrid}>
                    <div><span>Name</span><strong>{profile.name || 'Not available'}</strong></div>
                    <div><span>Nickname</span><strong>{profile.nickname || 'Not added'}</strong></div>
                    <div><span>Date of birth</span><strong>{this.formatDate(profile.dateOfBirth)}</strong></div>
                    <div><span>Gender</span><strong>{profile.gender ? profile.gender.replace(/_/g, ' ') : 'Not added'}</strong></div>
                </div>
                {profile.notes ? <p className={classes.NoteBox}>{profile.notes}</p> : null}
            </section>
        );
    }

    renderAssessmentSection(snapshot) {
        const assessment = snapshot.assessmentSummary || {};
        const latest = assessment.latest;

        return (
            <section className={classes.ReportSection}>
                <h2>Screening summary</h2>
                {!latest ? (
                    <p className={classes.EmptyText}>No saved screening result is available for this profile yet.</p>
                ) : (
                    <div>
                        <div className={classes.HighlightRow}>
                            <span className={this.bandClassName(latest.band)}>{this.formatBand(latest.band)}</span>
                            <strong>{latest.score}/{latest.maxScore}</strong>
                            <span>{this.formatDateTime(latest.createdAt)}</span>
                        </div>
                        <p>{latest.recommendation}</p>
                    </div>
                )}

                {assessment.recent && assessment.recent.length ? (
                    <div className={classes.SmallList}>
                        <h3>Recent screening history</h3>
                        {assessment.recent.map(session => (
                            <div className={classes.ListRow} key={session.id}>
                                <span>{this.formatDate(session.createdAt)}</span>
                                <strong>{this.formatBand(session.band)}</strong>
                                <small>{session.score}/{session.maxScore}</small>
                            </div>
                        ))}
                    </div>
                ) : null}
            </section>
        );
    }

    renderGameSection(snapshot) {
        const game = snapshot.gameSummary || {};
        const byLevel = game.byLevel || [];

        return (
            <section className={classes.ReportSection}>
                <h2>Emotion-game progress</h2>
                <div className={classes.DetailGrid}>
                    <div><span>Total attempts</span><strong>{game.totalAttempts || 0}</strong></div>
                    <div><span>Average accuracy</span><strong>{this.scoreLabel(game.averageAccuracy, '%')}</strong></div>
                    <div><span>Best accuracy</span><strong>{this.scoreLabel(game.bestAccuracy, '%')}</strong></div>
                </div>

                {byLevel.length ? (
                    <div className={classes.LevelGrid}>
                        {byLevel.map(level => (
                            <div className={classes.LevelCard} key={level.level}>
                                <h3>Level {level.level}</h3>
                                <p>{level.attempts} attempts</p>
                                <strong>{this.scoreLabel(level.averageAccuracy, '%')}</strong>
                                <small>Best: {this.scoreLabel(level.bestAccuracy, '%')}</small>
                            </div>
                        ))}
                    </div>
                ) : <p className={classes.EmptyText}>No game attempts have been saved yet.</p>}
            </section>
        );
    }

    renderWellbeingSection(snapshot) {
        const wellbeing = snapshot.wellbeingSummary || {};
        const latest = wellbeing.latest;
        const triggers = wellbeing.commonTriggers || [];
        const strategies = wellbeing.helpfulStrategies || [];

        return (
            <section className={classes.ReportSection}>
                <h2>Wellbeing tracker summary</h2>
                <div className={classes.DetailGrid}>
                    <div><span>Total logs</span><strong>{wellbeing.totalLogs || 0}</strong></div>
                    <div><span>Average wellbeing</span><strong>{this.scoreLabel(wellbeing.averageOverallScore, '%')}</strong></div>
                    <div><span>Common mood</span><strong>{this.formatMood(wellbeing.mostCommonMood)}</strong></div>
                    <div><span>Avg sensory overload</span><strong>{this.scoreLabel(wellbeing.averageSensoryOverload, '/5')}</strong></div>
                </div>

                {latest ? (
                    <div className={classes.NoteBox}>
                        <strong>Latest log: {this.formatDate(latest.logDate)} - {latest.overallScore}%</strong>
                        <p>Mood: {this.formatMood(latest.mood)}. Distress episodes: {latest.distressEpisodes}.</p>
                        {latest.notes ? <p>{latest.notes}</p> : null}
                    </div>
                ) : <p className={classes.EmptyText}>No wellbeing logs have been saved yet.</p>}

                <div className={classes.TwoColumnList}>
                    <div>
                        <h3>Common triggers</h3>
                        {triggers.length ? triggers.map(item => <span className={classes.Pill} key={item.label}>{item.label} ({item.count})</span>) : <p className={classes.EmptyText}>No trigger data yet.</p>}
                    </div>
                    <div>
                        <h3>Helpful strategies</h3>
                        {strategies.length ? strategies.map(item => <span className={classes.Pill} key={item.label}>{item.label} ({item.count})</span>) : <p className={classes.EmptyText}>No strategy data yet.</p>}
                    </div>
                </div>
            </section>
        );
    }

    renderRecommendations(snapshot) {
        const recommendations = snapshot.recommendations || [];

        return (
            <section className={classes.ReportSection}>
                <h2>Suggested review points</h2>
                <ol className={classes.Recommendations}>
                    {recommendations.map((item, index) => (
                        <li key={`${item}-${index}`}>{item}</li>
                    ))}
                </ol>
                <p className={classes.Disclaimer}>{snapshot.disclaimer}</p>
            </section>
        );
    }

    renderSavedReports() {
        return (
            <aside className={[classes.SavedReports, classes.NoPrint].join(' ')}>
                <h2>Saved reports</h2>
                {!this.state.reports.length ? <p>No saved reports yet. Generate one from the current preview.</p> : null}
                {this.state.reports.map(report => (
                    <div className={classes.SavedReport} key={report._id}>
                        <h3>{report.title}</h3>
                        <p>{this.formatDateTime(report.createdAt)}</p>
                        <p>
                            Screening: {this.formatBand(report.summary ? report.summary.assessmentBand : '')} | Game avg: {report.summary ? report.summary.gameAverageAccuracy : 0}% | Wellbeing: {report.summary ? report.summary.wellbeingAverageScore : 0}%
                        </p>
                        <div>
                            <button type="button" onClick={() => this.viewReport(report._id)}>View</button>
                            <button type="button" onClick={() => this.deleteReport(report._id)}>Delete</button>
                        </div>
                    </div>
                ))}
            </aside>
        );
    }

    renderReportPaper() {
        const snapshot = this.activeSnapshot();

        if (!snapshot) {
            return null;
        }

        const isSavedSnapshot = Boolean(this.state.selectedReport);

        return (
            <article className={classes.ReportPaper}>
                <div className={classes.ReportHeader}>
                    <div>
                        <p>AUTIASSIST SUPPORT REPORT</p>
                        <h1>{snapshot.profile ? snapshot.profile.name : 'Child'} progress summary</h1>
                        <span>{isSavedSnapshot ? 'Saved report snapshot' : 'Live preview from latest data'}</span>
                    </div>
                    <div className={classes.GeneratedBox}>
                        <strong>{this.formatDate(snapshot.generatedAt)}</strong>
                        <small>{this.formatDateTime(snapshot.generatedAt)}</small>
                    </div>
                </div>

                {this.renderSummaryCards(snapshot)}
                {this.renderProfileSection(snapshot)}
                {this.renderAssessmentSection(snapshot)}
                {this.renderGameSection(snapshot)}
                {this.renderWellbeingSection(snapshot)}
                {this.renderRecommendations(snapshot)}
            </article>
        );
    }

    render() {
        if (!this.state.profiles.length && !this.state.loading) {
            return (
                <div className={classes.Page}>
                    <section className={classes.EmptyState}>
                        <h1>Reports need a child profile first</h1>
                        <p>Create a child profile, then complete screenings, games, and wellbeing logs to build a review-ready report.</p>
                        <Link to="/profiles">Create profile</Link>
                    </section>
                </div>
            );
        }

        return (
            <div className={classes.Page}>
                <header className={[classes.Header, classes.NoPrint].join(' ')}>
                    <div>
                        <h1>Reports</h1>
                        <p>Generate a review-ready summary from screening results, emotion-game progress, and wellbeing logs.</p>
                    </div>
                </header>

                {this.renderControls()}

                {this.state.error ? <div className={[classes.Alert, classes.Error, classes.NoPrint].join(' ')}>{this.state.error}</div> : null}
                {this.state.success ? <div className={[classes.Alert, classes.Success, classes.NoPrint].join(' ')}>{this.state.success}</div> : null}
                {this.state.loading ? <div className={[classes.Alert, classes.NoPrint].join(' ')}>Loading report data...</div> : null}

                <div className={classes.Layout}>
                    <main>
                        {this.renderReportPaper()}
                    </main>
                    {this.renderSavedReports()}
                </div>
            </div>
        );
    }
}

export default Reports;
