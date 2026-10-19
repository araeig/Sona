import numpy as np

MOODS = [
    "calm", "energetic", "happy", "sad", "dark",
    "romantic", "dreamy", "aggressive", "epic", "groovy",
]
MOOD_PROMPTS = {}
GENRES = {
    "Pop": "pop music",
    "Rock": "rock music",
    "Electronic": "electronic music",
    "Hip-Hop": "hip hop music with rap vocals",
    "Jazz": "jazz music",
    "Classical": "classical music",
    "Lounge": "lounge music",
    "Metal": "heavy metal music",
    "Relaxation": "relaxing ambient music",
    "Soundtrack": "cinematic film soundtrack music",
}
MOODS_PER_TRACK = 2


class TaggingService:
    def __init__(self, clap):
        self.mood_vectors = np.array(
            [clap.embed_text(f"This is {MOOD_PROMPTS.get(mood, mood + ' music')}.") for mood in MOODS]
        )
        self.genre_names = list(GENRES.keys())
        self.genre_vectors = np.array(
            [clap.embed_text(f"This is {GENRES[name]}.") for name in self.genre_names]
        )
        self.mood_means = np.zeros(len(MOODS))
        self.genre_means = np.zeros(len(self.genre_names))

    def calibrate(self, embeddings):
        if not embeddings:
            return
        matrix = np.array(embeddings)
        self.mood_means = (matrix @ self.mood_vectors.T).mean(axis=0)
        self.genre_means = (matrix @ self.genre_vectors.T).mean(axis=0)

    def tag(self, embedding):
        vector = np.array(embedding)
        mood_scores = self.mood_vectors @ vector - self.mood_means
        genre_scores = self.genre_vectors @ vector - self.genre_means
        moods = [MOODS[i] for i in np.argsort(mood_scores)[::-1][:MOODS_PER_TRACK]]
        genre = self.genre_names[int(np.argmax(genre_scores))]
        return moods, genre