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
