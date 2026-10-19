import json
import os

from db import supabase
from services.clap_service import ClapService
from services.jamendo_service import JamendoService

DATASET_PATH = "data/mood_dataset.jsonl"
TRACKS_PER_MOOD = 100
SEARCH_TAGS = {
    "calm": ["calm", "peaceful", "relaxing"],
    "energetic": ["energetic", "upbeat"],
    "happy": ["happy", "joyful"],
    "sad": ["sad", "melancholic"],
    "dark": ["dark"],
    "romantic": ["romantic", "love"],
    "dreamy": ["dreamy", "ethereal"],
    "aggressive": ["aggressive", "angry"],
    "epic": ["epic"],
    "groovy": ["groovy", "funky"],
}
SYNONYMS = {
    "calm": "calm", "peaceful": "calm", "relaxing": "calm", "relaxation": "calm",
    "soft": "calm", "chill": "calm", "meditative": "calm",
    "energetic": "energetic", "upbeat": "energetic", "fast": "energetic", "powerful": "energetic",
    "happy": "happy", "joyful": "happy", "fun": "happy", "positive": "happy", "cheerful": "happy",
    "sad": "sad", "melancholic": "sad", "melancholy": "sad",
    "dark": "dark", "romantic": "romantic", "love": "romantic",
    "dreamy": "dreamy", "ethereal": "dreamy",
    "aggressive": "aggressive", "angry": "aggressive", "epic": "epic",
    "groovy": "groovy", "funky": "groovy",
}


def load_dataset():
    rows = {}
    if os.path.exists(DATASET_PATH):
        with open(DATASET_PATH, encoding="utf-8") as file:
            for line in file:
                row = json.loads(line)
                rows[row["jamendo_id"]] = row
    return rows


def moods_from_track(track):
    vartags = track.get("musicinfo", {}).get("tags", {}).get("vartags", [])
    return sorted({SYNONYMS[v] for v in vartags if v in SYNONYMS})


def main():
    os.makedirs("data", exist_ok=True)
    catalog_ids = {
        row["jamendo_id"]
        for row in supabase.table("tracks").select("jamendo_id").execute().data
    }
    dataset = load_dataset()
    jamendo = JamendoService()
    clap = ClapService()

    for mood, tags in SEARCH_TAGS.items():
        count = sum(1 for row in dataset.values() if mood in row["moods"])
        for tag in tags:
            if count >= TRACKS_PER_MOOD:
                break
            for track in jamendo.get_tracks_by_tag(tag, 200):
                if count >= TRACKS_PER_MOOD:
                    break
                jamendo_id = str(track["id"])
                if jamendo_id in catalog_ids or jamendo_id in dataset:
                    continue
                moods = moods_from_track(track)
                if mood not in moods or not track.get("audio"):
                    continue
                try:
                    embedding = clap.embed_audio(track["audio"])
                except Exception as e:
                    print(f"Skip {track['name'][:40]}: {e}")
                    continue
                row = {
                    "jamendo_id": jamendo_id,
                    "artist_id": str(track["artist_id"]),
                    "title": track["name"],
                    "moods": moods,
                    "embedding": embedding,
                }
                with open(DATASET_PATH, "a", encoding="utf-8") as file:
                    file.write(json.dumps(row) + "\n")
                dataset[jamendo_id] = row
                count += 1
                print(f"[{mood} {count}/{TRACKS_PER_MOOD}] {track['name'][:40]} -> {', '.join(moods)}")
        print(f"== {mood}: {count}")

    print(f"\nDone. Dataset size: {len(dataset)}")
    for mood in SEARCH_TAGS:
        print(f"  {mood:11} {sum(1 for row in dataset.values() if mood in row['moods'])}")


if __name__ == "__main__":
    main()