import React, { Component } from 'react';
import { Link, Redirect } from 'react-router-dom';
import { AuthContext } from '../../auth/AuthContext';
import classes from './Auth.module.css';

class Register extends Component {
    static contextType = AuthContext;

    state = {
        name: '',
        email: '',
        password: '',
        error: '',
        submitting: false
    };

    inputHandler = event => {
        this.setState({ [event.target.name]: event.target.value, error: '' });
    };

    submitHandler = async event => {
        event.preventDefault();
        this.setState({ submitting: true, error: '' });

        try {
            await this.context.register(this.state.name, this.state.email, this.state.password);
            this.props.history.push('/dashboard');
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to create account. Please try again.';
            this.setState({ error: message, submitting: false });
        }
    };

    render() {
        if (this.context.user) {
            return <Redirect to="/dashboard" />;
        }

        return (
            <div className={classes.Page}>
                <div className={classes.Card}>
                    <h1>Create caregiver account</h1>
                    <p className={classes.HelpText}>Caregiver accounts can use quizzes, screening tools, and progress features.</p>

                    {this.state.error ? <div className={classes.Error}>{this.state.error}</div> : null}

                    <form className={classes.Form} onSubmit={this.submitHandler}>
                        <label>Name</label>
                        <input
                            name="name"
                            type="text"
                            value={this.state.name}
                            onChange={this.inputHandler}
                            autoComplete="name"
                            required
                        />

                        <label>Email</label>
                        <input
                            name="email"
                            type="email"
                            value={this.state.email}
                            onChange={this.inputHandler}
                            autoComplete="email"
                            required
                        />

                        <label>Password</label>
                        <input
                            name="password"
                            type="password"
                            value={this.state.password}
                            onChange={this.inputHandler}
                            autoComplete="new-password"
                            minLength="8"
                            required
                        />

                        <button className={classes.Button} type="submit" disabled={this.state.submitting}>
                            {this.state.submitting ? 'Creating account...' : 'Create account'}
                        </button>
                    </form>

                    <p className={classes.FooterText}>
                        Already registered? <Link to="/login">Log in</Link>
                    </p>
                </div>
            </div>
        );
    }
}

export default Register;
