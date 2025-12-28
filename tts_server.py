import os
import io
import re
import uvicorn
from fastapi import FastAPI, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional

# --- Dependency Check ---
try:
    import torch
    device = "cuda" if torch.cuda.is_available() else "cpu"
except ImportError:
    torch = None
    device = "cpu"

try:
    from TTS.api import TTS
    TTS_AVAILABLE = True
except ImportError:
    print("Warning: 'TTS' library not found. Neural TTS will not be available.")
    print("Install with: pip install TTS (Requires Python 3.9-3.11)")
    TTS_AVAILABLE = False


# --- Configuration ---
app = FastAPI(title="Sakshi Vani Neural TTS Server (VITS)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Model Definitions ---
# Using VITS for offline, low-latency, high-quality speech
MODELS = {
    "en": "tts_models/en/vctk/vits",
    "hi": "tts_models/hi/mai/vits" 
}

loaded_models = {}

def load_models():
    """Loads models into memory if TTS is available."""
    if not TTS_AVAILABLE:
        return

    print(f"Loading Models on {device}...")
    
    # Load English
    try:
        print(f"Loading English: {MODELS['en']}...")
        loaded_models["en"] = TTS(MODELS["en"]).to(device)
        print("English Model Loaded.")
    except Exception as e:
        print(f"Failed to load English model: {e}")

    # Load Hindi
    try:
        print(f"Loading Hindi: {MODELS['hi']}...")
        loaded_models["hi"] = TTS(MODELS["hi"]).to(device)
        print("Hindi Model Loaded.")
    except Exception as e:
        print(f"Failed to load Hindi model: {e}")
        print("Tip: If 'mai/vits' fails, ensure you have internet for first download.")

# Startup load
if TTS_AVAILABLE:
    load_models()

# --- Helpers ---

def normalize_hindi_text(text: str) -> str:
    """
    Basic normalization for Hindi text.
    1. Expand common numbers (basic implementation)
    2. Remove nuktas if inconsistent (optional, keeping minimal for now)
    """
    # TODO: extensive number-to-text for Hindi is complex; 
    # relying on model's internal normalizer usually serves best unless specific issues arise.
    # Just trimming for now.
    return text.strip()

# --- Routes ---

class TTSRequest(BaseModel):
    text: str
    language: str = "en"  # 'en' or 'hi'
    speaker: Optional[str] = None # For multi-speaker models like VCTK

@app.get("/health")
def health_check():
    return {
        "status": "ok", 
        "tts_engine": "available" if TTS_AVAILABLE else "missing_lib",
        "models_loaded": list(loaded_models.keys()),
        "device": device
    }

@app.post("/tts")
def generate_speech(req: TTSRequest):
    if not TTS_AVAILABLE:
        raise HTTPException(status_code=503, detail="TTS Library missing")

    lang = req.language.lower()
    if lang not in loaded_models:
        # Check if we can fallback or if it's just not loaded
        if lang == 'hi' and 'en' in loaded_models:
             # Don't switch lang blindly, just error so client falls back to Native
             raise HTTPException(status_code=404, detail=f"Hindi model not loaded")
        
        if lang not in loaded_models:
             raise HTTPException(status_code=503, detail=f"Model for {lang} not loaded")

    tts = loaded_models[lang]
    text = req.text
    
    # Pre-processing
    if lang == 'hi':
        text = normalize_hindi_text(text)

    try:
        temp_file = "temp_output.wav"
        
        # Generation Args
        # English VCTK is multi-speaker. VITS VCTK has speakers like 'p225', 'p226'.
        # Hindi Mai VITS is usually single speaker unless specified otherwise.
        
        args = {
            "text": text,
            "file_path": temp_file
        }
        
        if lang == "en" and tts.is_multi_speaker:
            # p226 is a good standard VCTK voice (DeepMind often uses p225/p226 ref)
            # User suggested p225 (male), p226 (female), p228 (neutral)
            target_speaker = req.speaker if req.speaker else "p226" 
            args["speaker"] = target_speaker
            
        tts.tts_to_file(**args)

        with open(temp_file, "rb") as f:
            audio_data = f.read()
            
        return Response(content=audio_data, media_type="audio/wav")

    except Exception as e:
        print(f"Gen Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    print("Starting VITS Server on port 8000...")
    uvicorn.run(app, host="0.0.0.0", port=8000)
