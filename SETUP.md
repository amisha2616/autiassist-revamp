# AUTISMO / AutiAssist restore setup

This ZIP is a restored and cleaned-up version of the original MERN project. It keeps the old app running, adds a safer unified game-question API, adds demo quiz media, and prepares the codebase for a revamp.

## 1. Install required software

### Required

- Git
- Node.js and npm
- MongoDB Community Server, or a MongoDB Atlas database connection string
- VS Code or another editor

### Node version note

The current project still uses an old Create React App frontend with `react-scripts@3.4.3`. For the restored version, Node `16.20.2` is the safest choice.

For the later Vite/React rebuild, use a modern Node LTS version.

## 2. Restore the project locally

Extract the ZIP, then open a terminal inside the project folder.

```bash
cd autismo-revamp-starter
```

Create your environment file:

```bash
cp .env.example .env
```

On Windows PowerShell, use:

```powershell
copy .env.example .env
```

The default local database URL is:

```env
MONGODBURL=mongodb://127.0.0.1:27017/autismo
```

## 3. Install dependencies

```bash
npm run install:all
```

This installs both backend and frontend dependencies.

## 4. Start MongoDB

If MongoDB is installed locally, make sure the MongoDB service is running.

To check using MongoDB shell:

```bash
mongosh
```

Then exit:

```bash
exit
```

## 5. Seed demo game questions

The original local database was probably deleted with your local project, so the levels may be empty. Run this once:

```bash
npm run seed
```

This adds demo image, audio, and video questions using files in:

```text
client/public/demo-assets/
```

## 6. Run the project

```bash
npm run dev
```

Open:

```text
Frontend: http://localhost:3000
Backend health check: http://localhost:5000/api/health
```

## 7. Common issues

### `MONGODBURL` error

Make sure `.env` exists and contains:

```env
MONGODBURL=mongodb://127.0.0.1:27017/autismo
```

Or replace it with your MongoDB Atlas connection string.

### React OpenSSL error

This happens because the frontend is old. Best fix: use Node 16.20.2.

Temporary macOS/Linux fix:

```bash
NODE_OPTIONS=--openssl-legacy-provider npm run client
```

Temporary Windows PowerShell fix:

```powershell
$env:NODE_OPTIONS="--openssl-legacy-provider"
npm run client
```

### `nodemon` not found

Run:

```bash
npm install
```

or install everything again:

```bash
npm run install:all
```

## 8. What changed in this starter

- Added `.env.example`
- Added setup checker script
- Added MongoDB seed script
- Added demo image/audio/video files
- Added unified `GameQuestion` model
- Added `/api/game-questions` API
- Updated Level 1, Level 2, and Level 3 to use the new API
- Updated Upload Question to save questions through the new API
- Kept old `/levelOne`, `/levelTwo`, and `/levelThree` routes for compatibility
- Reworded quiz result messages so the app does not claim diagnosis

