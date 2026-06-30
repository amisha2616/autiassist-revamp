import React, { Component } from 'react';
import { Link, Redirect } from 'react-router-dom';
import { AuthContext } from '../../auth/AuthContext';
import classes from './Auth.module.css';

class Login extends Component {
    static contextType = AuthContext;

    state = {
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
            await this.context.login(this.state.email, this.state.password);
            const from = this.props.location.state && this.props.location.state.from
                ? this.props.location.state.from.pathname
                : '/dashboard';
            this.props.history.push(from);
        } catch (error) {
            const message = error.response && error.response.data && error.response.data.message
                ? error.response.data.message
                : 'Unable to log in. Please try again.';
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
                    <h1>Log in</h1>
                    <p className={classes.HelpText}>Access your caregiver or admin dashboard.</p>

                    {this.state.error ? <div className={classes.Error}>{this.state.error}</div> : null}

                    <form className={classes.Form} onSubmit={this.submitHandler}>
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
                            autoComplete="current-password"
                            required
                        />

                        <button className={classes.Button} type="submit" disabled={this.state.submitting}>
                            {this.state.submitting ? 'Logging in...' : 'Log in'}
                        </button>
                    </form>

                    <p className={classes.FooterText}>
                        New caregiver? <Link to="/register">Create an account</Link>
                    </p>
                </div>
            </div>
        );
    }
}

export default Login;
