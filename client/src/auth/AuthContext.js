import React, { Component, createContext } from 'react';
import axios from 'axios';

const TOKEN_KEY = 'autiassist_token';
const USER_KEY = 'autiassist_user';

export const AuthContext = createContext({
    user: null,
    token: null,
    loading: true,
    login: () => Promise.resolve(),
    register: () => Promise.resolve(),
    logout: () => {}
});

function setAuthHeader(token) {
    if (token) {
        axios.defaults.headers.common.Authorization = `Bearer ${token}`;
    } else {
        delete axios.defaults.headers.common.Authorization;
    }
}

class AuthProvider extends Component {
    state = {
        user: null,
        token: null,
        loading: true
    };

    componentDidMount() {
        const token = localStorage.getItem(TOKEN_KEY);
        const savedUser = localStorage.getItem(USER_KEY);

        if (!token) {
            this.setState({ loading: false });
            return;
        }

        setAuthHeader(token);

        this.setState(
            {
                token,
                user: savedUser ? JSON.parse(savedUser) : null
            },
            () => {
                axios.get('/api/auth/me')
                    .then(response => {
                        const user = response.data.user;
                        localStorage.setItem(USER_KEY, JSON.stringify(user));
                        this.setState({ user, loading: false });
                    })
                    .catch(() => {
                        this.logout();
                    });
            }
        );
    }

    login = async (email, password) => {
        const response = await axios.post('/api/auth/login', { email, password });
        const { token, user } = response.data;

        localStorage.setItem(TOKEN_KEY, token);
        localStorage.setItem(USER_KEY, JSON.stringify(user));
        setAuthHeader(token);

        this.setState({ token, user, loading: false });
        return user;
    };

    register = async (name, email, password) => {
        const response = await axios.post('/api/auth/register', { name, email, password });
        const { token, user } = response.data;

        localStorage.setItem(TOKEN_KEY, token);
        localStorage.setItem(USER_KEY, JSON.stringify(user));
        setAuthHeader(token);

        this.setState({ token, user, loading: false });
        return user;
    };

    logout = () => {
        localStorage.removeItem(TOKEN_KEY);
        localStorage.removeItem(USER_KEY);
        setAuthHeader(null);
        this.setState({ user: null, token: null, loading: false });
    };

    render() {
        return (
            <AuthContext.Provider
                value={{
                    user: this.state.user,
                    token: this.state.token,
                    loading: this.state.loading,
                    login: this.login,
                    register: this.register,
                    logout: this.logout
                }}
            >
                {this.props.children}
            </AuthContext.Provider>
        );
    }
}

export default AuthProvider;
