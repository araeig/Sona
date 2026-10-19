import io
import time

import librosa
import numpy as np
import requests
import torch
from transformers import ClapModel, ClapProcessor

MODEL_NAME = "laion/larger_clap_music_and_speech"
SAMPLE_RATE = 48000
CHUNK_SECONDS = 10


class ClapService:
    def __init__(self):
        self.processor = ClapProcessor.from_pretrained(MODEL_NAME)
        self.model = ClapModel.from_pretrained(MODEL_NAME)
        self.model.eval()

    def _download_audio(self, url, retries=3):
        for attempt in range(1, retries + 1):
            try:
                response = requests.get(url, timeout=60)
                response.raise_for_status()
                audio, _ = librosa.load(io.BytesIO(response.content), sr=SAMPLE_RATE, mono=True)
                return audio
            except Exception as e:
                print(f"Download error, attempt {attempt}: {e}")
                if attempt == retries:
                    raise
                time.sleep(2)

    def _take_chunks(self, audio):
        chunk_size = SAMPLE_RATE * CHUNK_SECONDS
        if len(audio) <= chunk_size:
            return [audio]
        chunks = []
        for position in (0.25, 0.5, 0.75):
            start = int((len(audio) - chunk_size) * position)
            chunks.append(audio[start:start + chunk_size])
        return chunks

    def _normalize(self, vectors):
        return vectors / np.linalg.norm(vectors, axis=-1, keepdims=True)

    def embed_audio(self, url):
        audio = self._download_audio(url)
        chunks = self._take_chunks(audio)
        inputs = self.processor(audio=chunks, sampling_rate=SAMPLE_RATE, return_tensors="pt")
        with torch.no_grad():
            features = self.model.get_audio_features(**inputs)
        features = getattr(features, "pooler_output", features)
        vectors = self._normalize(features.numpy())
        return self._normalize(vectors.mean(axis=0)).tolist()

    def embed_text(self, text):
        inputs = self.processor(text=[text], return_tensors="pt", padding=True)
        with torch.no_grad():
            features = self.model.get_text_features(**inputs)
        features = getattr(features, "pooler_output", features)
        return self._normalize(features.numpy())[0].tolist()