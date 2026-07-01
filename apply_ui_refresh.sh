#!/usr/bin/env bash
set -euo pipefail

if [ ! -f "package.json" ] || [ ! -d "client/src" ]; then
  echo "Run this script from the autismo-revamp-starter project root."
  exit 1
fi

if [ ! -f "client/src/components/Navigation/Toolbar/Toolbar.module.css" ]; then
  echo "Navigation files were not found. Make sure you are in the correct project."
  exit 1
fi

echo "Applying UI refresh: navbar fix, responsive layout, cards, forms, and landing polish..."

mkdir -p docs

cat > docs/UI_REFRESH_NOTES.md <<'DOC'
# UI Refresh Notes

This phase improves the visual layer without changing the database or backend logic.

## Updated areas

- Fixed navbar overflow on laptop-sized screens.
- Added a cleaner color system and global CSS variables.
- Improved cards, buttons, form inputs, spacing, focus states, and mobile responsiveness.
- Improved landing page hero sections.
- Improved dashboard-style pages such as profiles, screening, progress, wellbeing, and reports.
- Cleaned the admin upload question form so it no longer applies broad input styles globally.

## Test checklist

- Open `/` and check the landing page.
- Log in and open `/dashboard`.
- Check `/profiles`, `/screening/new`, `/game-progress`, `/wellbeing`, `/reports`, and `/upload`.
- Resize the browser. The top navigation should switch to the side menu on smaller widths.
DOC

cat > client/src/index.css <<'CSS'
:root {
  --color-bg: #f4f7f6;
  --color-bg-soft: #eaf3f1;
  --color-surface: #ffffff;
  --color-surface-muted: #f8fbfa;
  --color-text: #17212b;
  --color-text-soft: #52616b;
  --color-heading: #103f45;
  --color-primary: #135c5f;
  --color-primary-dark: #0d3f43;
  --color-primary-soft: #dcefed;
  --color-accent: #f36f45;
  --color-accent-soft: #fff1ec;
  --color-danger: #c73552;
  --color-danger-soft: #ffe8ee;
  --color-success: #1f8f5f;
  --color-success-soft: #e7f8ef;
  --color-warning: #a86900;
  --color-warning-soft: #fff3d8;
  --color-border: #d9e7e4;
  --shadow-sm: 0 6px 18px rgba(15, 56, 61, 0.08);
  --shadow-md: 0 14px 40px rgba(15, 56, 61, 0.14);
  --radius-sm: 10px;
  --radius-md: 16px;
  --radius-lg: 24px;
  --toolbar-height: 64px;
  --page-width: 1180px;
  --font-main: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
}

* {
  box-sizing: border-box;
}

html {
  min-height: 100%;
  overflow-x: hidden;
  scroll-behavior: smooth;
}

body {
  margin: 0;
  min-height: 100%;
  font-family: var(--font-main);
  color: var(--color-text);
  background:
    radial-gradient(circle at top left, rgba(19, 92, 95, 0.14), transparent 32rem),
    linear-gradient(180deg, #f9fcfb 0%, var(--color-bg) 42%, #eef6f4 100%);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

button,
input,
select,
textarea {
  font-family: inherit;
}

button,
a {
  -webkit-tap-highlight-color: transparent;
}

a {
  color: inherit;
}

button:focus-visible,
a:focus-visible,
input:focus-visible,
select:focus-visible,
textarea:focus-visible {
  outline: 3px solid rgba(243, 111, 69, 0.35);
  outline-offset: 3px;
}

img,
video {
  max-width: 100%;
}

code {
  font-family: source-code-pro, Menlo, Monaco, Consolas, "Courier New", monospace;
}

::selection {
  background: var(--color-primary-soft);
  color: var(--color-primary-dark);
}
CSS

cat > client/src/App.css <<'CSS'
.App {
  min-height: 100vh;
}

.Main {
  min-height: 100vh;
}
CSS

cat > client/src/components/Navigation/Toolbar/Toolbar.module.css <<'CSS'
.Toolbar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  width: 100%;
  height: var(--toolbar-height);
  background: rgba(13, 63, 67, 0.96);
  border-bottom: 1px solid rgba(255, 255, 255, 0.09);
  box-shadow: 0 10px 30px rgba(9, 36, 39, 0.18);
  backdrop-filter: blur(14px);
  z-index: 200;
}

.Toolbar__Navigation {
  width: 100%;
  max-width: 1320px;
  height: 100%;
  margin: 0 auto;
  padding: 0 clamp(12px, 3vw, 28px);
  display: flex;
  align-items: center;
  gap: 16px;
}

.Toolbar__Logo {
  flex: 0 0 auto;
}

.Toolbar__Logo a {
  color: #ffffff;
  text-decoration: none;
  font-size: clamp(1.15rem, 1.8vw, 1.55rem);
  font-weight: 900;
  letter-spacing: 0.02em;
}

.Spacer {
  flex: 1 1 auto;
  min-width: 8px;
}
CSS

cat > client/src/components/Navigation/NavigationItems/NavigationItems.module.css <<'CSS'
.NavigationItems {
  min-width: 0;
}

.NavigationItems ul {
  list-style-type: none;
  margin: 0;
  padding: 0;
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 4px;
  white-space: nowrap;
}

.NavigationItems li {
  padding: 0;
  display: flex;
  align-items: center;
}

.ButtonItem {
  display: flex;
  align-items: center;
}

.NavButton {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.12);
  color: #ffffff;
  cursor: pointer;
  font: inherit;
  font-size: 0.9rem;
  font-weight: 800;
  padding: 8px 11px;
  border-radius: 999px;
  transition: background 0.18s ease, transform 0.18s ease;
}

.NavButton:hover {
  background: rgba(255, 255, 255, 0.18);
  transform: translateY(-1px);
}

@media (max-width: 1180px) {
  .NavigationItems {
    display: none;
  }
}
CSS

cat > client/src/components/Navigation/NavigationItems/NavigationItem/NavigationItem.module.css <<'CSS'
.Normal {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 38px;
  padding: 8px 10px;
  border-radius: 999px;
  color: rgba(255, 255, 255, 0.9);
  text-decoration: none;
  font-size: 0.9rem;
  font-weight: 800;
  line-height: 1;
  transition: background 0.18s ease, color 0.18s ease, transform 0.18s ease;
}

.Normal:hover {
  background: rgba(255, 255, 255, 0.12);
  color: #ffffff;
  transform: translateY(-1px);
}

.Selected {
  background: #ffffff;
  color: var(--color-primary-dark);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.14);
}
CSS

cat > client/src/components/Navigation/SideDrawer/DrawerToggle/DrawerToggle.module.css <<'CSS'
.ToggleButton {
  width: 42px;
  height: 42px;
  display: flex;
  justify-content: center;
  align-items: center;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 12px;
  cursor: pointer;
  padding: 0;
}

.ToggleButton:focus {
  outline: none;
}

@media (min-width: 1181px) {
  .ToggleButton {
    display: none;
  }
}
CSS

cat > client/src/components/Navigation/SideDrawer/SideDrawer.module.css <<'CSS'
.SideDrawer {
  background: linear-gradient(180deg, var(--color-primary-dark), #125458);
  height: calc(100vh - var(--toolbar-height));
  width: min(82vw, 330px);
  box-shadow: 18px 0 45px rgba(9, 36, 39, 0.26);
  position: fixed;
  top: var(--toolbar-height);
  left: 0;
  z-index: 200;
  transform: translateX(-110%);
  transition: transform 0.26s ease-out;
  padding: 18px;
  overflow-y: auto;
}

.SideDrawer ul {
  width: 100%;
  list-style-type: none;
  display: flex;
  flex-direction: column;
  align-items: stretch;
  gap: 8px;
  margin: 0;
  padding: 0;
  font-size: 1rem;
}

.SideDrawer li {
  margin: 0;
}

.SideDrawer li a {
  width: 100%;
  justify-content: flex-start;
  padding: 13px 14px;
  border-radius: 14px;
}

.SideDrawer.Open {
  transform: translateX(0);
}

.SideDrawer__Logo {
  display: none;
}

.NavButton {
  width: 100%;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 14px;
  color: #ffffff;
  cursor: pointer;
  font: inherit;
  font-weight: 800;
  padding: 13px 14px;
  text-align: left;
}

.NavButton:hover {
  background: rgba(255, 255, 255, 0.16);
}
CSS

cat > client/src/components/Navigation/NavigationItems/NavigationItems.js <<'JS'
import React from 'react';
import NavigationItem from './NavigationItem/NavigationItem';
import { AuthContext } from '../../../auth/AuthContext';
import classes from './NavigationItems.module.css';

const navigationItems = props => (
    <AuthContext.Consumer>
        {auth => (
            <div className={classes.NavigationItems}>
                <ul>
                    <NavigationItem link="/levels">Games</NavigationItem>
                    <NavigationItem link="/camera">Observe</NavigationItem>
                    <NavigationItem link={auth.user ? "/screening/new" : "/questionarie"}>Screening</NavigationItem>
                    {auth.user ? <NavigationItem link="/profiles">Profiles</NavigationItem> : null}
                    {auth.user ? <NavigationItem link="/game-progress">Progress</NavigationItem> : null}
                    {auth.user ? <NavigationItem link="/wellbeing">Wellbeing</NavigationItem> : null}
                    {auth.user ? <NavigationItem link="/reports">Reports</NavigationItem> : null}
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
JS

cat > client/src/components/Navigation/SideDrawer/SideDrawer.js <<'JS'
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
                        <NavigationItem link="/levels">Games</NavigationItem>
                        <NavigationItem link="/camera">Live Observation</NavigationItem>
                        <NavigationItem link={auth.user ? "/screening/new" : "/questionarie"}>Screening</NavigationItem>
                        {auth.user ? <NavigationItem link="/profiles">Profiles</NavigationItem> : null}
                        {auth.user ? <NavigationItem link="/game-progress">Progress</NavigationItem> : null}
                        {auth.user ? <NavigationItem link="/wellbeing">Wellbeing</NavigationItem> : null}
                        {auth.user ? <NavigationItem link="/reports">Reports</NavigationItem> : null}
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
JS

cat > client/src/components/UI/Button/Button.css <<'CSS'
.Btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border-radius: 999px;
  outline: none;
  border: 0;
  cursor: pointer;
  white-space: nowrap;
  font-weight: 900;
  line-height: 1;
  letter-spacing: 0.01em;
  box-shadow: 0 12px 24px rgba(13, 63, 67, 0.18);
  transition: transform 0.18s ease, box-shadow 0.18s ease, background 0.18s ease;
}

.Btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 16px 30px rgba(13, 63, 67, 0.24);
}

.PrimaryBtn,
.OutlineBtn {
  background: var(--color-primary);
  color: #ffffff;
}

.OutlineBtn {
  border: 1px solid rgba(255, 255, 255, 0.28);
}

.MediumBtn {
  padding: 12px 20px;
  font-size: 1rem;
}

.LargeBtn {
  padding: 14px 26px;
  font-size: 1.05rem;
}

.MobileBtn {
  width: min(80%, 320px);
  padding: 14px 20px;
  font-size: 1.1rem;
}

.WideBtn {
  padding: 14px 44px;
  font-size: 1.05rem;
}

.PrimaryClr,
.BlueClr {
  background: var(--color-primary);
  color: #ffffff;
}

.RedClr {
  background: var(--color-accent);
  color: #ffffff;
}

.GreenClr {
  background: var(--color-success);
  color: #ffffff;
}
CSS

cat > client/src/components/Landing/Landing.module.css <<'CSS'
.Landing {
  margin-top: var(--toolbar-height);
  background: var(--color-bg);
}
CSS

cat > client/src/components/Landing/HeroSection/HeroSection.module.css <<'CSS'
.HeroSection {
  color: var(--color-text);
  padding: clamp(54px, 8vw, 104px) 0;
  margin: 0;
  overflow: hidden;
}

.Container {
  width: min(var(--page-width), calc(100% - 32px));
  margin: 0 auto;
}

.HeroRow,
.Row {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(280px, 0.85fr);
  align-items: center;
  gap: clamp(28px, 5vw, 72px);
}

.Reverse {
  grid-template-columns: minmax(280px, 0.85fr) minmax(0, 1fr);
}

.Reverse .Col:first-child {
  order: 2;
}

.Reverse .Col:last-child {
  order: 1;
}

.Col {
  min-width: 0;
}

.HeroTextWrapper,
.TextWrapper {
  max-width: 620px;
}

.TopLine {
  display: inline-flex;
  align-items: center;
  min-height: 30px;
  padding: 6px 12px;
  border-radius: 999px;
  background: rgba(243, 111, 69, 0.12);
  color: var(--color-accent);
  font-size: 0.82rem;
  line-height: 1;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin-bottom: 18px;
}

.Heading {
  margin: 0 0 22px;
  font-size: clamp(2.35rem, 5vw, 4.8rem);
  line-height: 0.98;
  font-weight: 950;
  color: #ffffff;
  letter-spacing: -0.055em;
}

.Dark {
  color: var(--color-heading);
}

.DarkBg {
  position: relative;
  background:
    radial-gradient(circle at 78% 18%, rgba(173, 210, 201, 0.34), transparent 28rem),
    linear-gradient(135deg, #12242c 0%, #163e43 48%, #0f2e35 100%);
}

.DarkBg::before {
  content: "";
  position: absolute;
  inset: auto -140px -220px auto;
  width: 460px;
  height: 460px;
  border-radius: 50%;
  background: rgba(243, 111, 69, 0.14);
  filter: blur(4px);
}

.HeroSubtitle {
  max-width: 560px;
  margin: 0 0 34px;
  font-size: clamp(1.02rem, 1.5vw, 1.18rem);
  line-height: 1.65;
  color: rgba(255, 255, 255, 0.86);
}

.HeroSubtitle.Dark {
  color: var(--color-text-soft);
}

.HeroImgWrapper {
  width: min(100%, 470px);
  margin: 0 auto;
  padding: clamp(12px, 2vw, 20px);
  border: 1px solid rgba(255, 255, 255, 0.14);
  border-radius: var(--radius-lg);
  background: rgba(255, 255, 255, 0.08);
  box-shadow: var(--shadow-md);
}

.HeroImg {
  display: block;
  width: 100%;
  max-height: 380px;
  object-fit: contain;
  margin: 0;
  border-radius: calc(var(--radius-lg) - 8px) !important;
}

img {
  border: 0;
  max-width: 100%;
  vertical-align: middle;
}

@media screen and (max-width: 860px) {
  .HeroSection {
    padding: 46px 0 58px;
  }

  .HeroRow,
  .Row,
  .Reverse {
    grid-template-columns: 1fr;
  }

  .Reverse .Col:first-child,
  .Reverse .Col:last-child {
    order: initial;
  }

  .HeroImgWrapper {
    width: min(100%, 360px);
  }
}
CSS

cat > client/src/components/Dashboard/Dashboard.module.css <<'CSS'
.Page {
  min-height: calc(100vh - var(--toolbar-height));
  padding: calc(var(--toolbar-height) + 44px) clamp(16px, 4vw, 40px) 56px;
  background: radial-gradient(circle at top right, rgba(19, 92, 95, 0.16), transparent 28rem), var(--color-bg);
  color: var(--color-text);
}

.Header {
  max-width: var(--page-width);
  margin: 0 auto 26px;
}

.Header h1 {
  margin: 0 0 10px;
  color: var(--color-heading);
  font-size: clamp(2rem, 4vw, 3rem);
  letter-spacing: -0.04em;
}

.Header p {
  max-width: 760px;
  margin: 0;
  color: var(--color-text-soft);
  line-height: 1.65;
}

.RoleBadge {
  display: inline-flex;
  align-items: center;
  margin-top: 16px;
  padding: 7px 13px;
  border-radius: 999px;
  background: var(--color-primary-soft);
  color: var(--color-primary-dark);
  font-weight: 900;
  text-transform: capitalize;
}

.Grid {
  max-width: var(--page-width);
  margin: 0 auto;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(245px, 1fr));
  gap: 18px;
}

.Card {
  background: var(--color-surface);
  color: var(--color-text);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 24px;
  box-shadow: var(--shadow-sm);
  transition: transform 0.18s ease, box-shadow 0.18s ease;
}

.Card:hover {
  transform: translateY(-3px);
  box-shadow: var(--shadow-md);
}

.Card h2 {
  margin: 0 0 10px;
  color: var(--color-heading);
}

.Card p {
  margin: 0 0 18px;
  line-height: 1.55;
  color: var(--color-text-soft);
}

.Card a,
.Card button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 0;
  border-radius: 999px;
  background: var(--color-primary);
  color: #ffffff;
  text-decoration: none;
  font-weight: 900;
  padding: 11px 16px;
  cursor: pointer;
  font-size: 14px;
}

.SecondaryButton {
  background: var(--color-danger) !important;
}
CSS

cat > client/src/components/Auth/Auth.module.css <<'CSS'
.Page {
  min-height: calc(100vh - var(--toolbar-height));
  padding: calc(var(--toolbar-height) + 54px) 16px 48px;
  background: radial-gradient(circle at top left, rgba(19, 92, 95, 0.16), transparent 28rem), var(--color-bg);
  color: var(--color-text);
  display: flex;
  justify-content: center;
  align-items: flex-start;
}

.Card {
  width: 100%;
  max-width: 460px;
  background: var(--color-surface);
  color: var(--color-text);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: clamp(24px, 4vw, 34px);
  box-shadow: var(--shadow-md);
}

.Card h1 {
  margin: 0 0 8px;
  color: var(--color-heading);
  font-size: 2.1rem;
  letter-spacing: -0.035em;
}

.HelpText {
  margin: 0 0 24px;
  line-height: 1.6;
  color: var(--color-text-soft);
}

.Form label {
  display: block;
  margin-bottom: 7px;
  font-weight: 900;
  color: var(--color-heading);
}

.Form input {
  width: 100%;
  box-sizing: border-box;
  height: 46px;
  margin-bottom: 16px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  padding: 0 13px;
  font-size: 15px;
  background: var(--color-surface-muted);
  color: var(--color-text);
}

.Button {
  width: 100%;
  min-height: 46px;
  border: 0;
  border-radius: 999px;
  background: var(--color-primary);
  color: #ffffff;
  font-size: 16px;
  font-weight: 900;
  cursor: pointer;
  box-shadow: 0 12px 24px rgba(13, 63, 67, 0.18);
}

.Button:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}

.Error {
  background: var(--color-danger-soft);
  color: var(--color-danger);
  padding: 12px;
  border-radius: var(--radius-sm);
  margin-bottom: 16px;
  font-weight: 800;
}

.FooterText {
  margin-top: 20px;
  text-align: center;
  color: var(--color-text-soft);
}

.FooterText a {
  color: var(--color-primary);
  font-weight: 900;
}
CSS

cat > client/src/containers/UploadQuestion/UploadQuestion.module.css <<'CSS'
.Container {
  min-height: calc(100vh - var(--toolbar-height));
  padding: calc(var(--toolbar-height) + 44px) clamp(16px, 4vw, 40px) 40px;
  background: var(--color-bg);
  display: grid;
  grid-template-columns: minmax(280px, 520px) minmax(220px, 380px);
  gap: clamp(24px, 5vw, 68px);
  justify-content: center;
  align-items: start;
}

.Wrapper {
  width: 100%;
  margin: 0;
  position: relative;
}

.Form {
  width: 100%;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: clamp(22px, 4vw, 30px);
  box-shadow: var(--shadow-md);
}

.Form::before {
  content: "Admin question upload";
  display: block;
  margin-bottom: 18px;
  color: var(--color-heading);
  font-size: 1.65rem;
  font-weight: 950;
  letter-spacing: -0.04em;
}

.Form label,
.DummyLabel {
  display: block;
  margin: 14px 0 7px;
  color: var(--color-heading);
  font-weight: 900;
}

.Form input,
.Dropdown {
  width: 100%;
  min-height: 46px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface-muted);
  color: var(--color-text);
  padding: 0 13px;
  font-size: 15px;
}

.SubmitBtn {
  width: 100%;
  min-height: 46px;
  margin-top: 18px;
  background: var(--color-primary);
  color: #ffffff;
  outline: none;
  border: 0;
  border-radius: 999px;
  font-weight: 950;
  font-size: 16px;
  transition: transform 0.18s ease, box-shadow 0.18s ease, background 0.18s ease;
  cursor: pointer;
  box-shadow: 0 12px 24px rgba(13, 63, 67, 0.18);
}

.SubmitBtn:hover {
  background: var(--color-primary-dark);
  transform: translateY(-2px);
}

.ImgContainer {
  width: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  padding-top: 38px;
}

.ImgContainer img {
  width: min(100%, 320px);
  height: auto;
  filter: drop-shadow(0 18px 28px rgba(13, 63, 67, 0.14));
}

@media screen and (max-width: 860px) {
  .Container {
    grid-template-columns: 1fr;
  }

  .ImgContainer {
    display: none;
  }
}
CSS

cat > client/src/components/LevelScreen/LevelScreen.module.css <<'CSS'
.PageContent {
  min-height: calc(100vh - var(--toolbar-height));
  margin-top: var(--toolbar-height);
  padding: clamp(28px, 5vw, 56px) clamp(16px, 4vw, 40px);
  background: var(--color-bg);
}

.circle_green {
  background: var(--color-primary-soft);
  width: 11rem;
  height: 11rem;
  position: relative;
  top: 40%;
  left: 50%;
  transform: translate(-50%, -50%);
  border-radius: 50%;
}

.LevelScreen_Header {
  display: flex;
  justify-content: center;
  align-items: center;
  width: min(var(--page-width), 100%);
  margin: 0 auto;
  font-size: clamp(2.1rem, 6vw, 4.5rem);
  font-weight: 950;
  letter-spacing: -0.05em;
  padding: 26px;
  color: var(--color-heading);
  background: var(--color-primary-soft);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
}

.LevelScreen_Container,
.LevelBtns_Container {
  display: flex;
  justify-content: center;
  align-items: center;
  width: min(var(--page-width), 100%);
  margin-left: auto;
  margin-right: auto;
}

.LevelScreen_Container {
  margin-top: 42px;
  gap: clamp(24px, 5vw, 70px);
  flex-wrap: wrap;
}

.LevelBtns_Container {
  gap: clamp(20px, 7vw, 120px);
  margin-top: 22px;
}

.LevelBtns_Container button {
  margin: 0;
}

.BtnContainer {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
  margin-top: 42px;
}

.LevelScreen_Container img {
  height: clamp(120px, 20vw, 220px);
  width: clamp(120px, 20vw, 220px);
  object-fit: contain;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 16px;
  box-shadow: var(--shadow-sm);
}

@media screen and (max-width: 520px) {
  .LevelBtns_Container {
    display: none;
  }

  .LevelScreen_Container {
    flex-direction: column;
  }
}
CSS

cat > client/src/containers/Level/Level.module.css <<'CSS'
.Container {
  min-height: calc(100vh - var(--toolbar-height));
  display: flex;
  justify-content: flex-start;
  align-items: center;
  flex-direction: column;
  margin: 0;
  padding: calc(var(--toolbar-height) + 24px) 16px 36px;
  background: var(--color-bg);
}

.LoaderWrapper {
  margin-top: 100px;
  display: flex;
  justify-content: center;
  width: 100%;
}

.ProfileSelector,
.AttemptNotice,
.MessageBox {
  width: min(780px, calc(100% - 24px));
  box-sizing: border-box;
  margin: 0 auto 18px;
  border-radius: var(--radius-md);
  border: 1px solid var(--color-border);
  background: var(--color-surface);
  color: var(--color-text);
  padding: 16px 18px;
  box-shadow: var(--shadow-sm);
}

.ProfileSelector {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  flex-wrap: wrap;
}

.ProfileSelector label {
  font-weight: 900;
  color: var(--color-heading);
}

.ProfileSelector select {
  min-width: min(100%, 240px);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface-muted);
  padding: 10px 12px;
  font-size: 15px;
}

.ProfileSelector p {
  width: 100%;
  margin: 6px 0 0;
  text-align: center;
  color: var(--color-warning);
}

.AttemptNotice {
  text-align: center;
  font-weight: 900;
}

.MessageBox {
  margin-top: 100px;
  text-align: center;
  font-size: 18px;
  line-height: 1.5;
}
CSS

cat > client/src/components/Question/Question.module.css <<'CSS'
.QuestionFile {
  width: min(780px, calc(100% - 24px));
  margin: 0 auto 20px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
  padding: clamp(18px, 4vw, 28px);
  overflow: hidden;
  color: var(--color-text);
}

.QuestionFile h1,
.QuestionFile h2,
.QuestionFile h3,
.QuestionFile p {
  color: var(--color-text);
}

.QuestionFile img,
.QuestionFile video {
  display: block;
  max-height: 360px;
  object-fit: contain;
  margin: 0 auto 18px;
  border-radius: var(--radius-md);
}
CSS

cat > client/src/components/UI/Option/Option.module.css <<'CSS'
.Option {
  width: min(100%, 620px);
  margin: 10px auto;
  padding: 14px 18px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  color: var(--color-text);
  font-weight: 900;
  cursor: pointer;
  box-shadow: var(--shadow-sm);
  transition: transform 0.18s ease, border 0.18s ease, background 0.18s ease;
}

.Option:hover {
  transform: translateY(-2px);
  border-color: var(--color-primary);
  background: var(--color-primary-soft);
}

.CorrectAnswer {
  border-color: var(--color-success);
  background: var(--color-success-soft);
  color: var(--color-success);
}

.IncorrectAnswer {
  border-color: var(--color-danger);
  background: var(--color-danger-soft);
  color: var(--color-danger);
}
CSS

cat > client/src/components/LevelCompleted/LevelCompleted.module.css <<'CSS'
.LevelCompleted {
  width: min(780px, calc(100% - 24px));
  margin: 0 auto;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
  padding: clamp(22px, 4vw, 34px);
  color: var(--color-text);
  text-align: center;
}

.LevelCompleteHeader {
  color: var(--color-heading);
  margin: 0 0 18px;
}

.StarsContainer {
  display: flex;
  justify-content: center;
  gap: 8px;
  margin: 12px 0 18px;
}

.Star1,
.Star2,
.Star3 {
  width: 54px;
  height: 54px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.Star1 img,
.Star2 img,
.Star3 img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

.ScoreContainer,
.AccuracyContainer,
.SaveNotice {
  margin: 12px auto;
  color: var(--color-text-soft);
  font-weight: 800;
}

.ButtonsContainer {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 12px;
  margin-top: 22px;
}

.ImageContainer {
  display: flex;
  justify-content: center;
  margin-top: 18px;
}

.ImageContainer img {
  max-height: 220px;
  object-fit: contain;
}
CSS

# Helper to append a clean override block without duplicating it on repeated runs.
refresh_block() {
  local file="$1"
  local content="$2"
  if [ ! -f "$file" ]; then
    return 0
  fi
  awk '
    /\/\* UI_REFRESH_START \*\// { skip=1; next }
    /\/\* UI_REFRESH_END \*\// { skip=0; next }
    skip != 1 { print }
  ' "$file" > "$file.tmp"
  mv "$file.tmp" "$file"
  {
    printf '\n/* UI_REFRESH_START */\n'
    printf '%s\n' "$content"
    printf '/* UI_REFRESH_END */\n'
  } >> "$file"
}

COMMON_PAGE_OVERRIDES='.Page {
  min-height: calc(100vh - var(--toolbar-height));
  padding: calc(var(--toolbar-height) + 44px) clamp(16px, 4vw, 40px) 56px;
  background: radial-gradient(circle at top right, rgba(19, 92, 95, 0.12), transparent 28rem), var(--color-bg);
  color: var(--color-text);
}

.Header,
.Layout,
.Notice,
.Error,
.Controls,
.EmptyState,
.Filters,
.SummaryGrid,
.Panel {
  max-width: var(--page-width);
}

.Header h1,
.EmptyState h1 {
  color: var(--color-heading);
  font-size: clamp(2rem, 4vw, 3rem);
  letter-spacing: -0.04em;
}

.Header p,
.EmptyState p,
.HelperText {
  color: var(--color-text-soft);
  line-height: 1.65;
}

.Card,
.ProfileCard,
.ResultCard,
.HistoryCard,
.SummaryCard,
.Panel,
.EmptyState,
.Filters,
.Controls,
.ReportPaper,
.SavedReports,
.Notice {
  background: var(--color-surface);
  color: var(--color-text);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-sm);
}

.Card h2,
.Card h3,
.ProfileCard h3,
.ListHeader h2,
.ResultCard h2,
.HistoryCard h2,
.Panel h2,
.EmptyState h2,
.SavedReports h2,
.ReportSection h2,
.ReportHeader h1,
.TemplateHeader h2 {
  color: var(--color-heading);
}

.Card p,
.ProfileCard p,
.HistoryItem p,
.Panel p,
.EmptyState p,
.SavedReports p,
.ReportSection p,
.LogCard p,
.LogTop p,
.SummaryCard span,
.SummaryCard small,
.LevelStats,
.AttemptCard p,
.AttemptMeta {
  color: var(--color-text-soft);
}

.Card input,
.Card select,
.Card textarea,
.TopControls select,
.Filters select,
.Controls select,
.Controls input {
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface-muted);
  color: var(--color-text);
  min-height: 44px;
}

.Card button,
.ProfileCard button,
.ListHeader a,
.SubmitButton,
.ResultCard button,
.Header a,
.EmptyState a,
.Controls button,
.Controls a,
.SavedReport button {
  border-radius: 999px;
  background: var(--color-primary);
  color: #ffffff;
  font-weight: 900;
  border: 0;
  transition: transform 0.18s ease, background 0.18s ease;
}

.Card button:hover,
.ProfileCard button:hover,
.ListHeader a:hover,
.SubmitButton:hover,
.ResultCard button:hover,
.Header a:hover,
.EmptyState a:hover,
.Controls button:hover,
.Controls a:hover,
.SavedReport button:hover {
  transform: translateY(-2px);
  background: var(--color-primary-dark);
}

.Error {
  background: var(--color-danger-soft);
  color: var(--color-danger);
}

.Success {
  background: var(--color-success-soft);
  color: var(--color-success);
}

.Warning,
.Disclaimer {
  background: var(--color-warning-soft);
  color: var(--color-warning);
}

@media (max-width: 760px) {
  .Page {
    padding: calc(var(--toolbar-height) + 28px) 14px 36px;
  }
}'

refresh_block client/src/components/Profiles/Profiles.module.css "$COMMON_PAGE_OVERRIDES"
refresh_block client/src/components/Screening/Screening.module.css "$COMMON_PAGE_OVERRIDES"
refresh_block client/src/components/GameProgress/GameProgress.module.css "$COMMON_PAGE_OVERRIDES"
refresh_block client/src/components/Wellbeing/Wellbeing.module.css "$COMMON_PAGE_OVERRIDES"
refresh_block client/src/components/Reports/Reports.module.css "$COMMON_PAGE_OVERRIDES"

refresh_block client/src/components/GameProgress/GameProgress.module.css '.Header a,
.EmptyState a {
  background: var(--color-primary);
  color: #ffffff;
}

.BarTrack {
  background: var(--color-primary-soft);
}

.BarFill {
  background: linear-gradient(90deg, var(--color-primary), var(--color-accent));
}

.AttemptCard,
.LevelCard,
.ListRow,
.SummaryCard {
  border-color: var(--color-border);
}'

refresh_block client/src/components/Wellbeing/Wellbeing.module.css '.BarTrack {
  background: var(--color-primary-soft);
}

.BarFill {
  background: linear-gradient(90deg, var(--color-primary), var(--color-accent));
}

.ScorePill,
.MetricGrid span,
.Pill {
  background: var(--color-primary-soft);
  color: var(--color-primary-dark);
}

.DeleteButton {
  border-radius: 999px;
  background: var(--color-danger);
}'

refresh_block client/src/components/Reports/Reports.module.css '.ReportPaper,
.SavedReports {
  border-radius: var(--radius-lg);
}

.SummaryCard,
.DetailGrid div,
.LevelCard,
.NoteBox,
.ListRow,
.SavedReport {
  border-color: var(--color-border);
}

.BandLow {
  background: var(--color-success-soft);
  color: var(--color-success);
}

.BandModerate {
  background: var(--color-warning-soft);
  color: var(--color-warning);
}

.BandHigh {
  background: var(--color-danger-soft);
  color: var(--color-danger);
}

@media print {
  .Page {
    padding: 0;
    background: #ffffff;
  }
}'

cat > client/src/components/UI/Button/LevelButton/LevelButton.module.css <<'CSS'
.LevelButton {
  height: clamp(120px, 18vw, 230px);
  width: clamp(120px, 18vw, 230px);
  cursor: pointer;
  background: var(--color-surface);
  outline: none;
  margin: 0;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  transition: transform 0.18s ease, box-shadow 0.18s ease, border-color 0.18s ease;
}

.LevelButton:hover {
  transform: translateY(-4px);
  border-color: var(--color-primary);
  box-shadow: var(--shadow-md);
}

.LevelButton img {
  width: 72%;
  height: 72%;
  object-fit: contain;
}
CSS

cat > client/src/components/UI/Button/LevelNoButton/LevelNoButton.module.css <<'CSS'
.LevelNoBtn {
  min-height: 46px;
  min-width: 140px;
  padding: 0 20px;
  background: var(--color-primary);
  color: #ffffff;
  font-size: 16px;
  font-weight: 900;
  text-align: center;
  cursor: pointer;
  outline: none;
  border: 0;
  border-radius: 999px;
  box-shadow: 0 12px 24px rgba(13, 63, 67, 0.18);
  transition: transform 0.18s ease, background 0.18s ease, box-shadow 0.18s ease;
}

.LevelNoBtn:hover {
  background: var(--color-primary-dark);
  transform: translateY(-2px);
}

.LevelNoBtn:focus {
  outline: none;
}

.Normal {
  text-decoration: none;
  color: #ffffff;
}

@media (max-width: 426px) {
  .LevelNoBtn {
    min-width: 120px;
  }
}
CSS

cat > client/src/components/UI/Button/NextButton/NextButton.module.css <<'CSS'
.NextBtn {
  min-height: 46px;
  min-width: 140px;
  padding: 0 20px;
  background: var(--color-primary);
  color: #ffffff;
  font-size: 16px;
  font-weight: 900;
  text-align: center;
  cursor: pointer;
  outline: none;
  border: 0;
  border-radius: 999px;
  box-shadow: 0 12px 24px rgba(13, 63, 67, 0.18);
  transition: transform 0.18s ease, background 0.18s ease, box-shadow 0.18s ease;
}

.NextBtn:hover {
  background: var(--color-primary-dark);
  transform: translateY(-2px);
}

.NextBtn:focus {
  outline: none;
}

@media (max-width: 426px) {
  .NextBtn {
    min-width: 120px;
    font-size: 15px;
  }
}
CSS

cat > client/src/components/FooterSection/FooterSection.module.css <<'CSS'
.FooterSection {
  margin-top: 42px;
  padding: 26px 16px;
  text-align: center;
  color: var(--color-text-soft);
}
CSS

# Some versions have this stylesheet loaded for blog pages.
if [ -f client/src/components/Blog/blog.css ]; then
cat > client/src/components/Blog/blog.css <<'CSS'
.blogContainer {
  min-height: calc(100vh - var(--toolbar-height));
  margin-top: var(--toolbar-height);
  margin-bottom: 0;
  padding: clamp(28px, 5vw, 56px) clamp(16px, 4vw, 40px);
  background: var(--color-bg);
  color: var(--color-text);
}

.blogWrapper {
  width: min(var(--page-width), 100%);
  margin: 28px auto 0;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 22px;
  align-items: stretch;
}

.blogContainer .LevelScreen_Header {
  width: min(var(--page-width), 100%);
  margin: 0 auto;
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: clamp(2.2rem, 6vw, 4.2rem);
  font-weight: 950;
  letter-spacing: -0.04em;
  padding: 26px;
  color: var(--color-heading);
  background: var(--color-primary-soft);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
}

.container {
  display: flex;
  justify-content: center;
}

.card {
  width: min(100%, 290px);
  height: 440px;
  perspective: 1000px;
}

.card__inner {
  width: 100%;
  height: 100%;
  transition: transform 0.45s ease;
  transform-style: preserve-3d;
  cursor: pointer;
  position: relative;
}

.card:hover .card__inner {
  transform: translateY(-4px);
}

.color__gradient {
  background: linear-gradient(135deg, var(--color-primary), #4e9f96);
}

.card__face {
  position: absolute;
  width: 100%;
  height: 100%;
  -webkit-backface-visibility: hidden;
  backface-visibility: hidden;
  overflow: hidden;
  border-radius: var(--radius-lg);
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  box-shadow: var(--shadow-md);
}

.card__content {
  width: 100%;
  height: 100%;
}

.card__header {
  position: relative;
  padding: 22px 18px 28px;
}

.card__header:after {
  content: "";
  display: block;
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, var(--color-primary), #77b7ad);
  z-index: -1;
  border-radius: 0 0 45% 0;
}

.pp {
  display: block;
  width: 130px;
  height: 130px;
  margin: 0 auto 18px;
  border-radius: 50%;
  background-color: #ffffff;
  border: 6px solid rgba(255, 255, 255, 0.88);
  object-fit: cover;
}

.card__body {
  padding: 24px;
}

.card__body h3 {
  color: var(--color-heading);
  font-size: 1.35rem;
  font-weight: 950;
  margin: 0;
  text-align: center;
}

.card__body p,
.card__body li {
  color: var(--color-text);
  font-size: 0.95rem;
  line-height: 1.5;
}

.color__gradient .card__body p,
.color__gradient .card__body li {
  color: #ffffff;
}
CSS
fi


cat > client/src/components/FooterSection/FooterSection.module.css <<'CSS'
.FooterSection {
  width: 100%;
  margin-top: 42px;
  padding: 26px 16px;
  text-align: center;
  color: var(--color-text-soft);
}
CSS

echo "UI refresh applied. Restart React if hot reload does not update every page."
echo "Next: test /, /dashboard, /profiles, /screening/new, /game-progress, /wellbeing, /reports, and /upload."
