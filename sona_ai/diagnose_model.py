import io
import sys

import librosa
import numpy as np
import requests
import torch
from transformers import ClapModel, ClapProcessor

from db import supabase

MODEL_NAME = sys.argv[1]
SAMPLE_RATE = 48000
QUERIES = [
    "calm piano",
    "heavy metal with distorted guitars",
    "epic orchestral soundtrack",
    "hip hop beat with rap vocals",
]
GENRES = ["Classical", "Metal", "Hip-Hop"]


def normalize(vectors):
    return vectors / np.linalg.norm(vectors, axis=-1, keepdims=True)


def features_to_numpy(features):
    features = getattr(features, "pooler_output", features)
    return normalize(features.numpy())


def load_middle_chunk(url):
    response = requests.get(url, timeout=60)
    response.raise_for_status()
    audio, _ = librosa.load(io.BytesIO(response.content), sr=SAMPLE_RATE, mono=True)
    chunk_size = SAMPLE_RATE * 10
    start = max(0, len(audio) // 2 - chunk_size // 2)
    return audio[start:start + chunk_size]


processor = ClapProcessor.from_pretrained(MODEL_NAME)
model = ClapModel.from_pretrained(MODEL_NAME)
model.eval()

text_inputs = processor(text=QUERIES, return_tensors="pt", padding=True)
with torch.no_grad():
    text_vectors = features_to_numpy(model.get_text_features(**text_inputs))

print(f"Model: {MODEL_NAME}")
print("\nText vs text:")
print(np.round(text_vectors @ text_vectors.T, 3))

print("\nTrack vs queries:", " | ".join(QUERIES))
for genre_name in GENRES:
    genre = supabase.table("genres").select("id").eq("name", genre_name).execute().data[0]
    track = (
        supabase.table("tracks")
        .select("title, audio_url")
        .eq("genre_id", genre["id"])
        .limit(1)
        .execute()
        .data[0]
    )
    chunk = load_middle_chunk(track["audio_url"])
    audio_inputs = processor(audio=[chunk], sampling_rate=SAMPLE_RATE, return_tensors="pt")
    with torch.no_grad():
        audio_vector = features_to_numpy(model.get_audio_features(**audio_inputs))[0]
    print(f"{genre_name:10} {np.round(audio_vector @ text_vectors.T, 3)}  {track['title'][:40]}")