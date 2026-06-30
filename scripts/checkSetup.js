const { execSync } = require('child_process');

function run(command) {
  try {
    return execSync(command, { stdio: ['ignore', 'pipe', 'ignore'] }).toString().trim();
  } catch (error) {
    return null;
  }
}

function printCheck(label, value, hint) {
  if (value) {
    console.log(`OK  ${label}: ${value}`);
  } else {
    console.log(`NO  ${label}: not found`);
    if (hint) console.log(`    ${hint}`);
  }
}

const nodeVersion = run('node -v');
const npmVersion = run('npm -v');
const gitVersion = run('git --version');
const mongoShellVersion = run('mongosh --version') || run('mongo --version');

printCheck('Node.js', nodeVersion, 'Install Node.js. For restoring this old CRA app, Node 16.20.2 is the safest option.');
printCheck('npm', npmVersion, 'npm comes with Node.js.');
printCheck('Git', gitVersion, 'Install Git before uploading to GitHub.');
printCheck('MongoDB shell', mongoShellVersion, 'Install MongoDB Community Server or use MongoDB Atlas.');

if (nodeVersion) {
  const major = Number(nodeVersion.replace('v', '').split('.')[0]);
  if (major >= 18) {
    console.log('\nNote: this restored app uses react-scripts 3.x. If npm start fails with an OpenSSL error, use Node 16.20.2 or set NODE_OPTIONS=--openssl-legacy-provider.');
  }
}
