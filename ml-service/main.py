from fastapi import FastAPI, UploadFile, File

app = FastAPI(title="AutiAssist ML Service")


@app.get("/health")
def health():
    return {"status": "ok", "service": "autiassist-ml-service"}


@app.post("/analyze-video")
async def analyze_video(file: UploadFile = File(...)):
    """Starter endpoint for future video-behaviour marker extraction.

    This intentionally returns neutral placeholder values. During the revamp,
    replace this with OpenCV/MediaPipe feature extraction such as blink rate,
    face visibility ratio, head movement variance, and repetitive motion score.
    """
    return {
        "filename": file.filename,
        "status": "received",
        "features": {
            "blinkRate": None,
            "faceVisibilityRatio": None,
            "headMovementVariance": None,
            "handMovementFrequency": None,
            "repetitiveMotionScore": None,
        },
        "summary": "Video received. Behaviour marker extraction is not implemented in this starter yet.",
        "disclaimer": "This service is for support and research use only. It does not diagnose autism.",
    }
