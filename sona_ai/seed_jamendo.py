import html

from db import supabase
from services.jamendo_service import JamendoService

GENRES = {
    "pop": "Pop",
    "rock": "Rock",
    "electronic": "Electronic",
    "hiphop": "Hip-Hop",
    "jazz": "Jazz",
    "classical": "Classical",
    "lounge": "Lounge",
    "metal": "Metal",
    "relaxation": "Relaxation",
    "soundtrack": "Soundtrack",
}
ARTISTS_PER_GENRE = 10
TRACKS_PER_ARTIST = 3

jamendo = JamendoService()


def build_tags(track):
    tags = track.get("musicinfo", {}).get("tags", {})
    result = [f"genre:{t}" for t in tags.get("genres", [])]
    result += [f"vartag:{t}" for t in tags.get("vartags", [])]
    result += [f"instrument:{t}" for t in tags.get("instruments", [])]
    return result


def pick_tracks(tracks):
    by_artist = {}
    for track in tracks:
        if not track.get("audio"):
            continue
        artist = str(track["artist_id"])
        if artist not in by_artist:
            if len(by_artist) == ARTISTS_PER_GENRE:
                continue
            by_artist[artist] = []
        if len(by_artist[artist]) < TRACKS_PER_ARTIST:
            by_artist[artist].append(track)
    return [track for group in by_artist.values() for track in group]


def save_genre(name):
    response = supabase.table("genres").upsert({"name": name}, on_conflict="name").execute()
    return response.data[0]["id"]


def save_artists(artist_ids):
    rows = []
    for artist in jamendo.get_artists(artist_ids):
        rows.append({
            "jamendo_id": str(artist["id"]),
            "name": html.unescape(artist["name"]).strip(),
            "avatar_url": artist.get("image") or None,
        })
    if not rows:
        return {}
    response = supabase.table("artists").upsert(rows, on_conflict="jamendo_id").execute()
    return {row["jamendo_id"]: row["id"] for row in response.data}


def save_tracks(tracks, artist_map, genre_id):
    rows = []
    for track in tracks:
        artist_id = artist_map.get(str(track["artist_id"]))
        if artist_id is None:
            continue
        rows.append({
            "jamendo_id": str(track["id"]),
            "title": html.unescape(track["name"]).strip(),
            "artist_id": artist_id,
            "genre_id": genre_id,
            "audio_url": track["audio"],
            "cover_url": track.get("image") or None,
            "duration_sec": track["duration"],
            "jamendo_tags": build_tags(track),
            "license_url": track.get("license_ccurl") or None,
        })
    if not rows:
        return []
    response = (
        supabase.table("tracks")
        .upsert(rows, on_conflict="jamendo_id", ignore_duplicates=True)
        .execute()
    )
    return response.data


def save_artist_genres(pairs):
    existing = supabase.table("artist_genres").select("artist_id, genre_id").execute().data
    existing_pairs = {(row["artist_id"], row["genre_id"]) for row in existing}
    new_rows = [
        {"artist_id": a, "genre_id": g} for (a, g) in pairs if (a, g) not in existing_pairs
    ]
    if new_rows:
        supabase.table("artist_genres").insert(new_rows).execute()


def main():
    total_tracks = 0
    for tag, name in GENRES.items():
        try:
            found = jamendo.get_genre_tracks(tag)
            genre_tracks = pick_tracks(found)
            if not genre_tracks:
                print(f"{name}: found {len(found)}, skipped")
                continue

            genre_id = save_genre(name)
            artist_map = save_artists(list({str(t["artist_id"]) for t in genre_tracks}))
            saved = save_tracks(genre_tracks, artist_map, genre_id)
            save_artist_genres({(row["artist_id"], genre_id) for row in saved})

            if genre_tracks[0].get("image"):
                supabase.table("genres").update(
                    {"cover_url": genre_tracks[0]["image"]}
                ).eq("id", genre_id).execute()

            total_tracks += len(saved)
            print(f"{name}: found {len(found)}, artists {len(artist_map)}, new tracks {len(saved)}")
        except Exception as e:
            print(f"Seed error ({name}): {e}")

    print(f"Done. New tracks added: {total_tracks}")


if __name__ == "__main__":
    main()