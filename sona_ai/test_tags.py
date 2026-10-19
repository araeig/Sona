import json
import random

import numpy as np

from db import supabase
from services.clap_service import ClapService

MOODS = [
    "calm", "energetic", "happy", "sad", "dark",
    "romantic", "dreamy", "aggressive", "epic", "groovy",
]
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

clap = ClapService()
mood_vectors = np.array([clap.embed_text(f"This is {mood} music.") for mood in MOODS])
genre_names = list(GENRES.keys())
genre_vectors = np.array([clap.embed_text(f"This is {GENRES[g]}.") for g in genre_names])

genres = {
    row["id"]: row["name"]
    for row in supabase.table("genres").select("id, name").execute().data
}
rows = (
    supabase.table("tracks")
    .select("id, title, genre_id, jamendo_tags, track_embeddings(embedding)")
    .execute()
    .data
)

tracks = []
vectors = []
for row in rows:
    data = row["track_embeddings"]
    if isinstance(data, list):
        data = data[0] if data else None
    if not data:
        continue
    tracks.append(row)
    vectors.append(json.loads(data["embedding"]))

track_matrix = np.array(vectors)
mood_raw = track_matrix @ mood_vectors.T
genre_raw = track_matrix @ genre_vectors.T
mood_centered = mood_raw - mood_raw.mean(axis=0)
genre_centered = genre_raw - genre_raw.mean(axis=0)


def genre_accuracy(scores):
    per_genre = {name: [0, 0] for name in genre_names}
    for i, track in enumerate(tracks):
        sona_genre = genres[track["genre_id"]]
        per_genre[sona_genre][1] += 1
        if genre_names[int(np.argmax(scores[i]))] == sona_genre:
            per_genre[sona_genre][0] += 1
    return per_genre


def mood_counts(scores):
    counts = {mood: 0 for mood in MOODS}
    for row in scores:
        for j in np.argsort(row)[::-1][:2]:
            counts[MOODS[j]] += 1
    return counts


raw_acc = genre_accuracy(genre_raw)
centered_acc = genre_accuracy(genre_centered)
print("Genre accuracy:      raw    centered")
for name in genre_names:
    r, t = raw_acc[name]
    c, _ = centered_acc[name]
    print(f"  {name:11}        {r:2}/{t:<3}  {c:2}/{t}")
raw_total = sum(c for c, _ in raw_acc.values())
centered_total = sum(c for c, _ in centered_acc.values())
print(f"  {'ALL':11}        {100 * raw_total / len(tracks):.0f}%    {100 * centered_total / len(tracks):.0f}%")

raw_counts = mood_counts(mood_raw)
centered_counts = mood_counts(mood_centered)
print("\nHow many tracks got each mood:  raw  centered")
for mood in MOODS:
    print(f"  {mood:11}                   {raw_counts[mood]:3}  {centered_counts[mood]:3}")

print("\nSample (centered):")
random.seed(1)
for i in random.sample(range(len(tracks)), 15):
    track = tracks[i]
    moods = [MOODS[j] for j in np.argsort(mood_centered[i])[::-1][:2]]
    ai_genre = genre_names[int(np.argmax(genre_centered[i]))]
    vartags = [t.split(":")[1] for t in track["jamendo_tags"] or [] if t.startswith("vartag:")]
    print(f"- {track['title'][:32]:32} | {genres[track['genre_id']]:10} -> {ai_genre:10} | {', '.join(moods):20} | jamendo: {', '.join(vartags)}")