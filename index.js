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

// Profile and saved screening APIs.
app.use('/api/profiles', require('./routes/profiles'));
app.use('/api/assessment-sessions', require('./routes/assessmentSessions'));
app.use('/api/game-attempts', require('./routes/gameAttempts'));
app.use('/api/wellbeing-logs', require('./routes/wellbeingLogs'));

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
