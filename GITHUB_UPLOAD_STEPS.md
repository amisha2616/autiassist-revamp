# Upload this restored project to GitHub

## 1. Open the project folder

```bash
cd autismo-revamp-starter
```

## 2. Check setup

```bash
npm run check:setup
```

## 3. Initialize Git

```bash
git init
git add .
git commit -m "Restore AUTISMO project from ZIP"
```

## 4. Create a GitHub repository

Create an empty repository on GitHub. Do not add a README, license, or gitignore there because this project already has them.

Suggested repository name:

```text
autiassist-revamp
```

## 5. Connect local project to GitHub

Replace `YOUR_USERNAME` with your GitHub username:

```bash
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/autiassist-revamp.git
git push -u origin main
```

## 6. Create a revamp branch

After the restored version is safely uploaded, create a separate branch for upgrades:

```bash
git checkout -b revamp-platform
git push -u origin revamp-platform
```

Use `main` as the safe restored backup and `revamp-platform` for new work.

## 7. Useful commit sequence

Use small commits like this:

```bash
git add .
git commit -m "Add unified game question API"

git add .
git commit -m "Add demo seed data"

git add .
git commit -m "Add setup documentation"
```

