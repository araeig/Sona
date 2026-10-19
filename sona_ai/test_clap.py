import numpy as np

from db import supabase
from services.clap_service import ClapService


def get_tracks(genre_name, count):
    genre = supabase.table("genres").select("id").eq("name", genre_name).execute().data[0]
    return (
        supabase.table("tracks")
        .select("title, audio_url")
        .eq("genre_id", genre["id"])
        .limit(count)
        .execute()
        .data
    )


clap = ClapService()
tracks = get_tracks("Metal", 2) + get_tracks("Classical", 1)

vectors = []
for track in tracks:
    vector = clap.embed_audio(track["audio_url"])
    print(f"{track['title']}: {len(vector)} numbers")
    vectors.append(np.array(vector))

print()
print("Metal 1 vs Metal 2:  ", round(float(vectors[0] @ vectors[1]), 3))
print("Metal 1 vs Classical:", round(float(vectors[0] @ vectors[2]), 3))
print("Metal 2 vs Classical:", round(float(vectors[1] @ vectors[2]), 3))