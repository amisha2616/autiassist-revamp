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
