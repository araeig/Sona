import numpy as np
import torch

from db import supabase
from services.clap_service import SAMPLE_RATE, ClapService

QUERIES = [
    "calm piano",
    "heavy metal with distorted guitars",
    "epic orchestral soundtrack",
    "hip hop beat with rap vocals",
]


def normalize(vectors):
    return vectors / np.linalg.norm(vectors, axis=-1, keepdims=True)


clap = ClapService()

text_inputs = clap.processor(text=QUERIES, return_tensors="pt", padding=True)
with torch.no_grad():
    raw_text = clap.model.get_text_features(**text_inputs)
print("1. get_text_features returns:", type(raw_text).__name__)
if not isinstance(raw_text, torch.Tensor):
    for name in ("pooler_output", "last_hidden_state", "text_embeds"):
        value = getattr(raw_text, name, None)
        if value is not None:
            print("  ", name, tuple(value.shape))

our_text = np.array([clap.embed_text(q) for q in QUERIES])
print("\n2. Our text vectors compared with each other:")
print(np.round(our_text @ our_text.T, 3))

track = supabase.table("tracks").select("title, audio_url").limit(1).execute().data[0]
audio = clap._download_audio(track["audio_url"])
chunk = clap._take_chunks(audio)[1]

inputs = clap.processor(
    text=QUERIES,
    audio=[chunk],
    sampling_rate=SAMPLE_RATE,
    return_tensors="pt",
    padding=True,
)
with torch.no_grad():
    outputs = clap.model(**inputs)
official_text = normalize(outputs.text_embeds.numpy())
official_audio = normalize(outputs.audio_embeds.numpy())

audio_inputs = clap.processor(audio=[chunk], sampling_rate=SAMPLE_RATE, return_tensors="pt")
with torch.no_grad():
    raw_audio = clap.model.get_audio_features(**audio_inputs)
raw_audio = getattr(raw_audio, "pooler_output", raw_audio)
our_audio = normalize(raw_audio.numpy())

print(f"\n3. Track: {track['title']}")
print("Our text vs official text (1.0 = same):", np.round(np.sum(our_text * official_text, axis=1), 3))
print("Our audio vs official audio (1.0 = same):", np.round(float(our_audio[0] @ official_audio[0]), 3))
print("Official audio vs each query:", np.round(official_audio[0] @ official_text.T, 3))
print("Our audio vs each query:", np.round(our_audio[0] @ our_text.T, 3))