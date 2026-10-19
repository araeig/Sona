import json

import numpy as np

from db import supabase
from services.clap_service import ClapService

MOODS = [
    "calm", "energetic", "happy", "sad", "dark",
    "romantic", "dreamy", "aggressive", "epic", "groovy",
]
OLD_PHRASES = {mood: f"{mood} music" for mood in MOODS}
NEW_PHRASES = dict(
    OLD_PHRASES,
    calm="calm, quiet and relaxing music",
    energetic="energetic upbeat music with a fast tempo",
    dreamy="dreamy ethereal ambient music",
    aggressive="aggressive music with harsh screaming vocals",
    epic="epic orchestral music with powerful drums and brass",
)
NEW_OLD_AGGRESSIVE = dict(NEW_PHRASES, aggressive="aggressive music")
SYNONYMS = {
    "calm": "calm", "peaceful": "calm", "relaxing": "calm", "relaxation": "calm",
    "soft": "calm", "chill": "calm", "meditative": "calm",
    "energetic": "energetic", "upbeat": "energetic", "fast": "energetic", "powerful": "energetic",
    "happy": "happy", "joyful": "happy", "fun": "happy", "positive": "happy", "cheerful": "happy",
    "sad": "sad", "melancholic": "sad", "melancholy": "sad",
    "dark": "dark", "romantic": "romantic", "love": "romantic", "dreamy": "dreamy",
    "aggressive": "aggressive", "angry": "aggressive", "epic": "epic",
    "groovy": "groovy", "funky": "groovy",
}
LOUD = {"energetic", "aggressive", "epic"}
QUIET = {"calm", "dreamy", "sad"}

clap = ClapService()
genres = {
    row["id"]: row["name"]
    for row in supabase.table("genres").select("id, name").execute().data
}
rows = (
    supabase.table("tracks")
    .select("genre_id, jamendo_tags, track_embeddings(embedding)")
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
    vartags = [t.split(":")[1] for t in row["jamendo_tags"] or [] if t.startswith("vartag:")]
    tracks.append({
        "genre": genres[row["genre_id"]],
        "jamendo": {SYNONYMS[v] for v in vartags if v in SYNONYMS},
    })
    vectors.append(json.loads(data["embedding"]))
matrix = np.array(vectors)


def predict(phrases, zscore=False, second_threshold=None):
    text_vectors = np.array([clap.embed_text(f"This is {phrases[m]}.") for m in MOODS])
    scores = matrix @ text_vectors.T
    scores = scores - scores.mean(axis=0)
    if zscore:
        scores = scores / scores.std(axis=0)
    predictions = []
    for row in scores:
        order = np.argsort(row)[::-1]
        moods = {MOODS[order[0]]}
        if second_threshold is None or row[order[1]] >= second_threshold:
            moods.add(MOODS[order[1]])
        predictions.append(moods)
    return predictions


def evaluate(name, predictions):
    with_jamendo = hits = conflicts = tags_checked = tags_correct = rock_aggressive = 0
    for track, moods in zip(tracks, predictions):
        if track["genre"] == "Rock" and "aggressive" in moods:
            rock_aggressive += 1
        jamendo = track["jamendo"]
        if not jamendo:
            continue
        with_jamendo += 1
        tags_checked += len(moods)
        tags_correct += len(moods & jamendo)
        if moods & jamendo:
            hits += 1
        loud_vs_calm = moods & LOUD and "calm" in jamendo and not jamendo & {"energetic", "aggressive"}
        calm_vs_loud = moods & QUIET and jamendo & {"energetic", "aggressive"} and "calm" not in jamendo
        if loud_vs_calm or calm_vs_loud:
            conflicts += 1
    avg_tags = sum(len(m) for m in predictions) / len(predictions)
    print(
        f"{name:40} hits {hits:2}/{with_jamendo}  "
        f"tags correct {100 * tags_correct / tags_checked:3.0f}%  "
        f"conflicts {conflicts:2}  rock aggressive {rock_aggressive:2}/19  avg tags {avg_tags:.1f}"
    )


evaluate("A. old phrases", predict(OLD_PHRASES))
evaluate("B. new phrases (now in base)", predict(NEW_PHRASES))
evaluate("C. new phrases + old aggressive", predict(NEW_OLD_AGGRESSIVE))
evaluate("D. C + zscore", predict(NEW_OLD_AGGRESSIVE, zscore=True))
evaluate("E. D + 2nd mood only if strong", predict(NEW_OLD_AGGRESSIVE, zscore=True, second_threshold=1.0))