#!/usr/bin/env bash
set -euo pipefail

if [ ! -f "package.json" ] || [ ! -d "client/src" ]; then
  echo "Run this script from the autismo-revamp-starter project root."
  exit 1
fi

echo "Applying AutiAssist authentication and role upgrade..."

mkdir -p middleware models routes scripts client/src/auth client/src/components/Auth client/src/components/Dashboard client/src/components/ProtectedRoute

node <<'NODE'
const fs = require('fs');
const file = 'package.json';
const pkg = JSON.parse(fs.readFileSync(file, 'utf8'));
pkg.dependencies = pkg.dependencies || {};
pkg.dependencies.bcryptjs = pkg.dependencies.bcryptjs || '^2.4.3';
pkg.dependencies.jsonwebtoken = pkg.dependencies.jsonwebtoken || '^9.0.2';
pkg.scripts = pkg.scripts || {};
pkg.scripts['create:admin'] = 'node scripts/createAdmin.js';
fs.writeFileSync(file, JSON.stringify(pkg, null, 2) + '\n');
NODE

if [ -f ".env.example" ] && ! grep -q '^JWT_SECRET=' .env.example; then
  cat >> .env.example <<'EOF'
JWT_SECRET=replace_this_with_a_long_random_secret
JWT_EXPIRES_IN=7d
EOF
fi

if [ -f ".env" ] && ! grep -q '^JWT_SECRET=' .env; then
  cat >> .env <<'EOF'
JWT_SECRET=dev_only_change_this_later_autiassist_secret
JWT_EXPIRES_IN=7d
EOF
fi

cat > models/user.js <<'EOF'
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      minlength: 2
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Use a valid email address.']
    },
    passwordHash: {
      type: String,
      required: true
    },
    role: {
      type: String,
      enum: ['caregiver', 'clinician', 'admin'],
      default: 'caregiver',
      index: true
    }
  },
  { timestamps: true }
);

userSchema.methods.toSafeJSON = function toSafeJSON() {
  return {
    id: this._id,
    name: this.name,
    email: this.email,
    role: this.role,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

module.exports = mongoose.model('User', userSchema);
EOF

cat > middleware/auth.js <<'EOF'
const jwt = require('jsonwebtoken');
const User = require('../models/user');

const jwtSecret = process.env.JWT_SECRET || 'dev_only_change_this_later_autiassist_secret';

async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;

    if (!token) {
      return res.status(401).json({ message: 'Login is required.' });
    }

    const payload = jwt.verify(token, jwtSecret);
    const user = await User.findById(payload.id);

    if (!user) {
      return res.status(401).json({ message: 'Invalid or expired login session.' });
    }

    req.user = user;
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Invalid or expired login session.' });
  }
}

function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Login is required.' });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ message: 'You do not have permission to access this feature.' });
    }

    next();
  };
}

module.exports = {
  requireAuth,
  requireRole
};
EOF

cat > routes/auth.js <<'EOF'
const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/user');
const { requireAuth } = require('../middleware/auth');

const jwtSecret = process.env.JWT_SECRET || 'dev_only_change_this_later_autiassist_secret';
const jwtExpiresIn = process.env.JWT_EXPIRES_IN || '7d';

function createToken(user) {
  return jwt.sign(
    {
      id: user._id,
      role: user.role
    },
    jwtSecret,
    { expiresIn: jwtExpiresIn }
  );
}

function sendAuthResponse(res, user) {
  res.json({
    token: createToken(user),
    user: user.toSafeJSON()
  });
}

router.post('/register', async (req, res) => {
  try {
    const name = String(req.body.name || '').trim();
    const email = String(req.body.email || '').trim().toLowerCase();
    const password = String(req.body.password || '');

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email, and password are required.' });
    }

    if (password.length < 8) {
      return res.status(400).json({ message: 'Password must be at least 8 characters long.' });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ message: 'An account already exists with this email.' });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const user = await User.create({
      name,
      email,
      passwordHash,
      role: 'caregiver'
    });

    sendAuthResponse(res, user);
  } catch (error) {
    res.status(500).json({ message: 'Unable to create account.', error: error.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const password = String(req.body.password || '');

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required.' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Invalid email or password.' });
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Invalid email or password.' });
    }

    sendAuthResponse(res, user);
  } catch (error) {
    res.status(500).json({ message: 'Unable to log in.', error: error.message });
  }
});

router.get('/me', requireAuth, (req, res) => {
  res.json({ user: req.user.toSafeJSON() });
});

module.exports = router;
EOF

cat > scripts/createAdmin.js <<'EOF'
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/user');

require('dotenv').config();

async function main() {
  const email = String(process.argv[2] || process.env.ADMIN_EMAIL || '').trim().toLowerCase();
  const password = String(process.argv[3] || process.env.ADMIN_PASSWORD || '');
  const name = String(process.argv[4] || process.env.ADMIN_NAME || 'Admin User').trim();

  if (!email || !password) {
    console.error('Usage: npm run create:admin -- admin@example.com StrongPass123');
    process.exit(1);
  }

  if (password.length < 8) {
    console.error('Admin password must be at least 8 characters long.');
    process.exit(1);
  }

  const mongoUrl = process.env.MONGODBURL || 'mongodb://127.0.0.1:27017/autismo';
  await mongoose.connect(mongoUrl, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    useCreateIndex: true,
    useFindAndModify: false
  });

  const passwordHash = await bcrypt.hash(password, 12);
  const existingUser = await User.findOne({ email });

  if (existingUser) {
    existingUser.name = name;
    existingUser.passwordHash = passwordHash;
    existingUser.role = 'admin';
    await existingUser.save();
    console.log(`Admin account updated: ${email}`);
  } else {
    await User.create({
      name,
      email,
      passwordHash,
      role: 'admin'
    });
    console.log(`Admin account created: ${email}`);
  }

  await mongoose.disconnect();
}

main().catch(async error => {
  console.error(error.message);
  try {
    await mongoose.disconnect();
  } catch (disconnectError) {
    // Ignore disconnect errors.
  }
  process.exit(1);
});
EOF

cat > routes/gameQuestions.js <<'EOF'
const router = require('express').Router();
const GameQuestion = require('../models/gameQuestion');
const { requireAuth, requireRole } = require('../middleware/auth');

const mediaTypeByLevel = {
  1: 'image',
  2: 'audio',
  3: 'video'
};

function normalizeQuestionPayload(body) {
  const level = Number(body.level);
  return {
    level,
    mediaType: body.mediaType || mediaTypeByLevel[level],
    question: body.question,
    hostedURL: body.hostedURL,
    correct_answer: body.correct_answer,
    incorrect_answers: body.incorrect_answers,
    difficulty: body.difficulty || 'easy',
    tags: Array.isArray(body.tags) ? body.tags : [],
    source: body.source || 'manual'
  };
}

router.get('/', async (req, res) => {
  try {
    const filter = {};
    if (req.query.level) {
      filter.level = Number(req.query.level);
    }

    const questions = await GameQuestion.find(filter).sort({ createdAt: -1 });
    res.json(questions);
  } catch (error) {
    res.status(500).json({ message: 'Unable to fetch questions.', error: error.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const question = await GameQuestion.findById(req.params.id);

    if (!question) {
      return res.status(404).json({ message: 'Invalid question id.' });
    }

    res.json(question);
  } catch (error) {
    res.status(500).json({ message: 'Unable to fetch question.', error: error.message });
  }
});

router.post('/', requireAuth, requireRole('admin'), async (req, res) => {
  try {
    const question = await GameQuestion.create(normalizeQuestionPayload(req.body));
    res.status(201).json(question);
  } catch (error) {
    res.status(400).json({ message: 'Unable to create question.', error: error.message });
  }
});

router.put('/:id', requireAuth, requireRole('admin'), async (req, res) => {
  try {
    const question = await GameQuestion.findByIdAndUpdate(
      req.params.id,
      normalizeQuestionPayload(req.body),
      { new: true, runValidators: true }
    );

    if (!question) {
      return res.status(404).json({ message: 'Invalid question id.' });
    }

    res.json(question);
  } catch (error) {
    res.status(400).json({ message: 'Unable to update question.', error: error.message });
  }
});

router.delete('/:id', requireAuth, requireRole('admin'), async (req, res) => {
  try {
    const question = await GameQuestion.findByIdAndDelete(req.params.id);

    if (!question) {
      return res.status(404).json({ message: 'Invalid question id.' });
    }

    res.json({ message: 'Question deleted successfully.' });
  } catch (error) {
    res.status(500).json({ message: 'Unable to delete question.', error: error.message });
  }
});

module.exports = router;
EOF

cat > index.js <<'EOF'
const express = require('express');
const mongoose = require('mongoose');
const path = require('path');
const cors = require('cors');

require('dotenv').config();

const app = express();
const port = process.env.PORT || 5000;
const mongoUrl = process.env.MONGODBURL || 'mongodb://127.0.0.1:27017/autismo';
const clientUrl = process.env.CLIENT_URL || 'http://localhost:3000';

app.use(express.json({ limit: '25mb' }));
app.use(cors({ origin: clientUrl, credentials: true }));

mongoose
  .connect(mongoUrl, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    useCreateIndex: true,
    useFindAndModify: false
  })
  .then(() => {
    console.log('MongoDB connected successfully');
  })
  .catch(error => {
    console.error('MongoDB connection failed:', error.message);
  });

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'autiassist-api',
    database: mongoose.connection.readyState === 1 ? 'connected' : 'not-connected'
  });
});

// Authentication and role routes.
app.use('/api/auth', require('./routes/auth'));

// New unified quiz API for the revamp.
app.use('/api/game-questions', require('./routes/gameQuestions'));

// Legacy routes are kept so the original app does not break while migrating.
app.use('/levelOne', require('./routes/level1'));
app.use('/levelTwo', require('./routes/level2'));
app.use('/levelThree', require('./routes/level3'));

app.use(express.static('client/build'));
app.get('*', (req, res) => {
  res.sendFile(path.resolve(__dirname, 'client', 'build', 'index.html'));
});

app.listen(port, () => {
  console.log(`Listening at ${port}`);
});
EOF

cat > client/src/auth/AuthContext.js <<'EOF'
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
EOF

cat > client/src/components/ProtectedRoute/ProtectedRoute.js <<'EOF'
import React from 'react';
import { Route, Redirect } from 'react-router-dom';
import { AuthContext } from '../../auth/AuthContext';

const ProtectedRoute = ({ component: Component, roles, ...rest }) => (
    <AuthContext.Consumer>
        {auth => (
            <Route
                {...rest}
                render={props => {
                    if (auth.loading) {
                        return <div style={{ paddingTop: '90px', textAlign: 'center' }}>Checking login...</div>;
                    }

                    if (!auth.user) {
                        return <Redirect to={{ pathname: '/login', state: { from: props.location } }} />;
                    }

                    if (roles && roles.length > 0 && !roles.includes(auth.user.role)) {
                        return <Redirect to="/dashboard" />;
                    }

                    return <Component {...props} />;
                }}
            />
        )}
    </AuthContext.Consumer>
);

export default ProtectedRoute;
EOF

cat > client/src/components/Auth/Auth.module.css <<'EOF'
.Page {
    min-height: calc(100vh - 56px);
    padding: 96px 16px 48px;
    background: #20262f;
    color: #ffffff;
    display: flex;
    justify-content: center;
    align-items: flex-start;
}

.Card {
    width: 100%;
    max-width: 440px;
    background: #ffffff;
    color: #20262f;
    border-radius: 12px;
    padding: 28px;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.25);
}

.Card h1 {
    margin: 0 0 8px;
    color: #144C52;
}

.HelpText {
    margin: 0 0 22px;
    line-height: 1.5;
    color: #4c5965;
}

.Form label {
    display: block;
    margin-bottom: 6px;
    font-weight: 700;
}

.Form input {
    width: 100%;
    box-sizing: border-box;
    height: 40px;
    margin-bottom: 16px;
    border: 1px solid #cbd5dd;
    border-radius: 6px;
    padding: 0 10px;
    font-size: 15px;
}

.Button {
    width: 100%;
    min-height: 42px;
    border: 0;
    border-radius: 6px;
    background: #144C52;
    color: #ffffff;
    font-size: 16px;
    font-weight: 700;
    cursor: pointer;
}

.Button:disabled {
    opacity: 0.65;
    cursor: not-allowed;
}

.Error {
    background: #ffe9ef;
    color: #b0002f;
    padding: 10px;
    border-radius: 6px;
    margin-bottom: 16px;
}

.FooterText {
    margin-top: 18px;
    text-align: center;
    color: #4c5965;
}

.FooterText a {
    color: #144C52;
    font-weight: 700;
}
EOF

cat > client/src/components/Auth/Login.js <<'EOF'
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
EOF

cat > client/src/components/Auth/Register.js <<'EOF'
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
EOF

cat > client/src/components/Dashboard/Dashboard.module.css <<'EOF'
.Page {
    min-height: calc(100vh - 56px);
    padding: 96px 32px 48px;
    background: #20262f;
    color: #ffffff;
}

.Header {
    max-width: 1040px;
    margin: 0 auto 24px;
}

.Header h1 {
    margin: 0 0 8px;
    font-size: 36px;
}

.Header p {
    margin: 0;
    color: #d6e4e2;
    line-height: 1.5;
}

.RoleBadge {
    display: inline-block;
    margin-top: 14px;
    padding: 6px 12px;
    border-radius: 999px;
    background: #144C52;
    color: #ffffff;
    font-weight: 700;
    text-transform: capitalize;
}

.Grid {
    max-width: 1040px;
    margin: 0 auto;
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));
    gap: 18px;
}

.Card {
    background: #ffffff;
    color: #20262f;
    border-radius: 12px;
    padding: 22px;
    box-shadow: 0 8px 30px rgba(0, 0, 0, 0.22);
}

.Card h2 {
    margin: 0 0 8px;
    color: #144C52;
}

.Card p {
    margin: 0 0 18px;
    line-height: 1.5;
    color: #4c5965;
}

.Card a,
.Card button {
    display: inline-block;
    border: 0;
    border-radius: 6px;
    background: #144C52;
    color: #ffffff;
    text-decoration: none;
    font-weight: 700;
    padding: 10px 14px;
    cursor: pointer;
    font-size: 14px;
}

.SecondaryButton {
    background: #f00946 !important;
}
EOF

cat > client/src/components/Dashboard/Dashboard.js <<'EOF'
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
                        <h2>Emotion games</h2>
                        <p>Practice image, audio, and video-based emotion recognition activities.</p>
                        <Link to="/levels">Open games</Link>
                    </div>

                    <div className={classes.Card}>
                        <h2>Screening support</h2>
                        <p>Use the caregiver questionnaire for a non-diagnostic risk summary.</p>
                        <Link to="/questionarie">Open screening</Link>
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
EOF

cat > client/src/App.js <<'EOF'
import React, { Component } from 'react';
import { Route, Switch } from 'react-router';
import { BrowserRouter } from 'react-router-dom';
import AuthProvider from './auth/AuthContext';
import ProtectedRoute from './components/ProtectedRoute/ProtectedRoute';
import Toolbar from './components/Navigation/Toolbar/Toolbar';
import SideDrawer from './components/Navigation/SideDrawer/SideDrawer';
import Backdrop from './components/UI/Backdrop/Backdrop';
import Landing from './components/Landing/Landing';
import LevelScreen from './components/LevelScreen/LevelScreen';
import Credits from './components/Credits/Credits';
import Level1 from './components/Levels/Level1/Level1';
import Level2 from './components/Levels/Level2/Level2';
import Level3 from './components/Levels/Level3/Level3';
import UploadQuestion from './containers/UploadQuestion/UploadQuestion';
import FaceExpression from './components/FaceExpression/FaceExpression';
import Quiz from './components/Quiz/quiz';
import QuizAdult from './components/QuizAdult/adultQuiz';
import QuizScreen from './components/QuizScreen/QuizScreen';
import blog from './components/Blog/blog';
import Login from './components/Auth/Login';
import Register from './components/Auth/Register';
import Dashboard from './components/Dashboard/Dashboard';
import './App.css';

class App extends Component {
  state = {
    sideDrawerOpen: false
  };

  drawerToggleClickHandler = () => {
    this.setState(prevState => {
      return { sideDrawerOpen: !prevState.sideDrawerOpen };
    });
  };

  backdropClickHandler = () => {
    this.setState({
      sideDrawerOpen: false
    });
  }

  render() {
    let backdrop;

    if (this.state.sideDrawerOpen) {
      backdrop = <Backdrop click={this.backdropClickHandler} />;
    }

    return (
      <div className="App" style={{ height: '100%' }}>
        <BrowserRouter>
          <AuthProvider>
            <div className="ToolbarSideDrawer">
              <Toolbar show={this.state.sideDrawerOpen} drawerClickHandler={this.drawerToggleClickHandler} />
              <SideDrawer show={this.state.sideDrawerOpen} />
              {backdrop}
            </div>

            <main className="Main" style={{ height: '100%' }}>
              <Switch>
                <Route path="/login" exact component={Login} />
                <Route path="/register" exact component={Register} />
                <ProtectedRoute path="/dashboard" exact component={Dashboard} />
                <Route path="/levels" exact component={LevelScreen} />
                <Route path="/level1" exact component={Level1} />
                <Route path="/level2" exact component={Level2} />
                <Route path="/level3" exact component={Level3} />
                <ProtectedRoute path="/upload" exact component={UploadQuestion} roles={['admin']} />
                <Route path="/camera" exact component={FaceExpression} />
                <Route path="/credits" exact component={Credits} />
                <Route path="/question&answer" exact component={Quiz} />
                <Route path="/question&answeradult" exact component={QuizAdult} />
                <Route path="/questionarie" exact component={QuizScreen} />
                <Route path="/blog" exact component={blog} />
                <Route path="/" component={Landing} />
              </Switch>
            </main>
          </AuthProvider>
        </BrowserRouter>
      </div>
    );
  }
}

export default App;
EOF

cat > client/src/components/Navigation/Toolbar/Toolbar.js <<'EOF'
import React from 'react';
import NavigationItems from '../NavigationItems/NavigationItems';
import DrawerToggle from '../SideDrawer/DrawerToggle/DrawerToggle';
import classes from './Toolbar.module.css';

const toolbar = props => {
    return (
        <div className={classes.Toolbar}>
            <nav className={classes.Toolbar__Navigation}>
                <div>
                    <DrawerToggle icon={props.show} click={props.drawerClickHandler} />
                </div>
                <div className={classes.Toolbar__Logo}><a href="/">AUTIASSIST</a></div>
                <div className={classes.Spacer}></div>
                <NavigationItems />
            </nav>
        </div>
    )
}

export default toolbar;
EOF

cat > client/src/components/Navigation/NavigationItems/NavigationItems.js <<'EOF'
import React from 'react';
import NavigationItem from './NavigationItem/NavigationItem';
import { AuthContext } from '../../../auth/AuthContext';
import classes from './NavigationItems.module.css';

const navigationItems = props => (
    <AuthContext.Consumer>
        {auth => (
            <div className={classes.NavigationItems}>
                <ul>
                    <NavigationItem link="/levels">Quiz</NavigationItem>
                    <NavigationItem link="/camera">Live Observation</NavigationItem>
                    <NavigationItem link="/questionarie">Screening Tool</NavigationItem>
                    <NavigationItem link="/blog">Blog</NavigationItem>

                    {auth.user ? <NavigationItem link="/dashboard">Dashboard</NavigationItem> : null}
                    {auth.user && auth.user.role === 'admin' ? <NavigationItem link="/upload">Admin</NavigationItem> : null}
                    {!auth.user ? <NavigationItem link="/login">Login</NavigationItem> : null}
                    {auth.user ? (
                        <li className={classes.ButtonItem}>
                            <button className={classes.NavButton} onClick={auth.logout}>Logout</button>
                        </li>
                    ) : null}
                </ul>
            </div>
        )}
    </AuthContext.Consumer>
);

export default navigationItems;
EOF

cat > client/src/components/Navigation/NavigationItems/NavigationItems.module.css <<'EOF'
.NavigationItems ul {
    list-style-type: none;
    margin: 0;
    padding: 0;
    display: flex;
    align-items: center;
}

.NavigationItems li {
    padding: 0 0.5rem;
}

.ButtonItem {
    display: flex;
    align-items: center;
}

.NavButton {
    background: transparent;
    border: 0;
    color: #ffffff;
    cursor: pointer;
    font: inherit;
    font-weight: 700;
    padding: 0;
}

.NavButton:hover {
    text-decoration: underline;
}

@media (max-width: 768px) {
    .NavigationItems {
        display: none;
    }
}
EOF

cat > client/src/components/Navigation/SideDrawer/SideDrawer.js <<'EOF'
import React from 'react';
import NavigationItem from '../NavigationItems/NavigationItem/NavigationItem';
import { AuthContext } from '../../../auth/AuthContext';
import classes from './SideDrawer.module.css';

const sideDrawer = props => {
    let drawerClasses = [classes.SideDrawer];
    if (props.show) {
        drawerClasses = [classes.SideDrawer, classes.Open];
    }

    return (
        <AuthContext.Consumer>
            {auth => (
                <nav className={drawerClasses.join(' ')}>
                    <ul>
                        <NavigationItem link="/levels">Quiz</NavigationItem>
                        <NavigationItem link="/camera">Live Observation</NavigationItem>
                        <NavigationItem link="/questionarie">Screening Tool</NavigationItem>
                        <NavigationItem link="/blog">Blog</NavigationItem>
                        {auth.user ? <NavigationItem link="/dashboard">Dashboard</NavigationItem> : null}
                        {auth.user && auth.user.role === 'admin' ? <NavigationItem link="/upload">Admin Upload</NavigationItem> : null}
                        {!auth.user ? <NavigationItem link="/login">Login</NavigationItem> : null}
                        {auth.user ? (
                            <li>
                                <button className={classes.NavButton} onClick={auth.logout}>Logout</button>
                            </li>
                        ) : null}
                    </ul>
                </nav>
            )}
        </AuthContext.Consumer>
    )
};

export default sideDrawer;
EOF

cat > client/src/components/Navigation/SideDrawer/SideDrawer.module.css <<'EOF'
.SideDrawer {
    background-color: #3F7B70;
    height: 91.65%;
    width: 70%;
    max-width: 320px;
    box-shadow: 0px 0px 7px rgba(0, 0, 0, 0.5);
    position: fixed;
    top: 56px;
    left: 0;
    z-index: 200;
    transform: translateX(-120%);
    transition: transform 0.3s ease-out;
}

.SideDrawer ul {
    width: 100%;
    list-style-type: none;
    display: flex;
    flex-direction: column;
    justify-content: center;
    font-size: 1.2rem;
}

.SideDrawer li {
    margin: 0.5rem 0;
}

.SideDrawer.Open {
    transform: translateX(0);
}

.SideDrawer__Logo {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 100%;
    margin-left: -1rem;
}

.SideDrawer__Logo a {
    color: #ffffff;
    text-decoration: none;
    font-size: 1.5rem;
}

.NavButton {
    background: transparent;
    border: 0;
    color: #ffffff;
    cursor: pointer;
    font: inherit;
    padding: 0;
}

.NavButton:hover {
    text-decoration: underline;
}
EOF

node <<'NODE'
const fs = require('fs');
const file = 'client/src/containers/UploadQuestion/UploadQuestion.js';
let text = fs.readFileSync(file, 'utf8');
text = text.replace(
"                const message = err.response && err.response.data && err.response.data.error\n                    ? err.response.data.error\n                    : 'Unable to add question.';",
"                const message = err.response && err.response.data && (err.response.data.message || err.response.data.error)\n                    ? (err.response.data.message || err.response.data.error)\n                    : 'Unable to add question.';"
);
fs.writeFileSync(file, text);
NODE

echo "Auth upgrade files added."
echo "Next commands:"
echo "  npm install bcryptjs jsonwebtoken --legacy-peer-deps"
echo "  npm run create:admin -- admin@autiassist.local Admin@12345"
echo "  export NODE_OPTIONS=--openssl-legacy-provider"
echo "  npm run dev"
