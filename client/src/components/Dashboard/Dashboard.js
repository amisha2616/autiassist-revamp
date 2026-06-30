import React, { Component } from 'react';
import { Link } from 'react-router-dom';
import { AuthContext } from '../../auth/AuthContext';
import classes from './Dashboard.module.css';

class Dashboard extends Component {
    static contextType = AuthContext;

    logoutHandler = () => {
        this.context.logout();
    };

    render() {
        const user = this.context.user;

        if (!user) {
            return null;
        }

        return (
            <div className={classes.Page}>
                <section className={classes.Header}>
                    <h1>Welcome, {user.name}</h1>
                    <p>
                        This dashboard is the new base for profiles, screening results, game progress,
                        and admin tools.
                    </p>
                    <span className={classes.RoleBadge}>{user.role}</span>
                </section>

                <section className={classes.Grid}>
                    <div className={classes.Card}>
                        <h2>Child profiles</h2>
                        <p>Create child profiles so screenings and future progress tracking are saved properly.</p>
                        <Link to="/profiles">Manage profiles</Link>
                    </div>
                    <div className={classes.Card}>
                        <h2>Emotion games</h2>
                        <p>Practice image, audio, and video-based emotion recognition activities.</p>
                        <Link to="/levels">Open games</Link>
                    </div>


                    <div className={classes.Card}>
                        <h2>Game progress</h2>
                        <p>Review saved emotion-game attempts, accuracy trends, and recent practice history.</p>
                        <Link to="/game-progress">View game progress</Link>
                    </div>

                    <div className={classes.Card}>
                        <h2>Screening support</h2>
                        <p>Use the caregiver questionnaire for a non-diagnostic risk summary.</p>
                        <Link to="/screening/new">Start saved screening</Link>
                    </div>

                    <div className={classes.Card}>
                        <h2>Live observation</h2>
                        <p>Practice identifying facial expressions using browser-based detection.</p>
                        <Link to="/camera">Start practice</Link>
                    </div>

                    {user.role === 'admin' ? (
                        <div className={classes.Card}>
                            <h2>Admin question upload</h2>
                            <p>Add image, audio, and video questions to the unified game-question API.</p>
                            <Link to="/upload">Upload question</Link>
                        </div>
                    ) : null}

                    <div className={classes.Card}>
                        <h2>Account</h2>
                        <p>Signed in as {user.email}.</p>
                        <button className={classes.SecondaryButton} onClick={this.logoutHandler}>Log out</button>
                    </div>
                </section>
            </div>
        );
    }
}

export default Dashboard;
