import React, { Component } from 'react';
import axios from 'axios';
import { Link } from 'react-router-dom';
import classes from './Profiles.module.css';

class Profiles extends Component {
    state = {
        profiles: [],
        name: '',
        nickname: '',
        dateOfBirth: '',
        gender: '',
        notes: '',
        loading: true,
        submitting: false,
        error: '',
        success: ''
    };

    componentDidMount() {
        this.loadProfiles();
    }

    loadProfiles = async () => {
        this.setState({ loading: true, error: '' });

        try {
            const response = await axios.get('/api/profiles');
            this.setState({ profiles: response.data, loading: false });
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to load profiles.';
            this.setState({ error: message, loading: false });
        }
    };

    inputHandler = event => {
        this.setState({ [event.target.name]: event.target.value, error: '', success: '' });
    };

    submitHandler = async event => {
        event.preventDefault();
        this.setState({ submitting: true, error: '', success: '' });

        try {
            await axios.post('/api/profiles', {
                name: this.state.name,
                nickname: this.state.nickname,
                dateOfBirth: this.state.dateOfBirth,
                gender: this.state.gender,
                notes: this.state.notes
            });

            this.setState({
                name: '',
                nickname: '',
                dateOfBirth: '',
                gender: '',
                notes: '',
                submitting: false,
                success: 'Profile created successfully.'
            });
            this.loadProfiles();
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to create profile.';
            this.setState({ error: message, submitting: false });
        }
    };

    archiveProfile = async profileId => {
        const confirmed = window.confirm('Archive this profile? Saved screening history will remain available in the database.');
        if (!confirmed) {
            return;
        }

        try {
            await axios.delete(`/api/profiles/${profileId}`);
            this.loadProfiles();
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to archive profile.';
            this.setState({ error: message });
        }
    };

    formatDate(date) {
        if (!date) {
            return 'Not added';
        }
        return new Date(date).toLocaleDateString();
    }

    render() {
        return (
            <div className={classes.Page}>
                <section className={classes.Header}>
                    <h1>Child profiles</h1>
                    <p>Create profiles so screening results, game progress, and wellbeing logs can be linked to the right child.</p>
                </section>

                <section className={classes.Layout}>
                    <form className={classes.Card} onSubmit={this.submitHandler}>
                        <h2>Add profile</h2>

                        {this.state.error ? <div className={classes.Error}>{this.state.error}</div> : null}
                        {this.state.success ? <div className={classes.Success}>{this.state.success}</div> : null}

                        <label>Child name</label>
                        <input name="name" value={this.state.name} onChange={this.inputHandler} required />

                        <label>Nickname</label>
                        <input name="nickname" value={this.state.nickname} onChange={this.inputHandler} />

                        <label>Date of birth</label>
                        <input name="dateOfBirth" type="date" value={this.state.dateOfBirth} onChange={this.inputHandler} />

                        <label>Gender</label>
                        <select name="gender" value={this.state.gender} onChange={this.inputHandler}>
                            <option value="">Select</option>
                            <option value="female">Female</option>
                            <option value="male">Male</option>
                            <option value="other">Other</option>
                            <option value="prefer_not_to_say">Prefer not to say</option>
                        </select>

                        <label>Notes</label>
                        <textarea
                            name="notes"
                            rows="4"
                            value={this.state.notes}
                            onChange={this.inputHandler}
                            placeholder="Optional caregiver notes, communication preferences, or sensory considerations."
                        />

                        <button type="submit" disabled={this.state.submitting}>
                            {this.state.submitting ? 'Saving...' : 'Save profile'}
                        </button>
                    </form>

                    <div className={classes.List}>
                        <div className={classes.ListHeader}>
                            <h2>Saved profiles</h2>
                            <Link to="/screening/new">Start screening</Link>
                        </div>

                        {this.state.loading ? <p>Loading profiles...</p> : null}

                        {!this.state.loading && this.state.profiles.length === 0 ? (
                            <div className={classes.Empty}>
                                <h3>No profiles yet</h3>
                                <p>Add your first child profile to save screening history.</p>
                            </div>
                        ) : null}

                        {this.state.profiles.map(profile => (
                            <article key={profile._id} className={classes.ProfileCard}>
                                <div>
                                    <h3>{profile.name}</h3>
                                    <p>Nickname: {profile.nickname || 'Not added'}</p>
                                    <p>Date of birth: {this.formatDate(profile.dateOfBirth)}</p>
                                    <p>Gender: {profile.gender ? profile.gender.replace(/_/g, ' ') : 'Not added'}</p>
                                    {profile.notes ? <p className={classes.Notes}>{profile.notes}</p> : null}
                                </div>
                                <button type="button" onClick={() => this.archiveProfile(profile._id)}>Archive</button>
                            </article>
                        ))}
                    </div>
                </section>
            </div>
        );
    }
}

export default Profiles;
