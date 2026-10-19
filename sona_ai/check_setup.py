import sys

from supabase import create_client

from config import SUPABASE_URL, SUPABASE_SERVICE_KEY

print("Python:", sys.version.split()[0])

try:
    import torch
    import transformers
    import librosa
    import fastapi
    print("torch:", torch.__version__)
    print("transformers:", transformers.__version__)
    print("librosa:", librosa.__version__)
    print("fastapi:", fastapi.__version__)
except ImportError as e:
    print("Package not installed:", e)

try:
    supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    response = supabase.table("tracks").select("id", count="exact").execute()
    print("Supabase OK, tracks in database:", response.count)
except Exception as e:
    print("Supabase error:", e)