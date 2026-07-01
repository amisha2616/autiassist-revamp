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
