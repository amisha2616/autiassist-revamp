# ML service starter

This folder is a starter placeholder for the future Python video-analysis service.

The restored MERN app does not depend on this service yet. Add it during the revamp phase after the main project is running and uploaded to GitHub.

## Setup

```bash
cd ml-service
python -m venv .venv
```

Activate it.

macOS/Linux:

```bash
source .venv/bin/activate
```

Windows PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Run:

```bash
uvicorn main:app --reload --port 8000
```

Health check:

```text
http://localhost:8000/health
```

