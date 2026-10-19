import json

from db import supabase


class TracksService:
    def get_pending(self, limit):
        return (
            supabase.table("tracks")
            .select("id, title, audio_url")
            .eq("ai_status", "pending")
            .limit(limit)
            .execute()
            .data
        )

    def get_track(self, track_id):
        rows = (
            supabase.table("tracks")
            .select("id, title, audio_url")
            .eq("id", track_id)
            .execute()
            .data
        )
        return rows[0] if rows else None

    def set_status(self, track_id, status):
        supabase.table("tracks").update({"ai_status": status}).eq("id", track_id).execute()

    def reset_stuck(self):
        supabase.table("tracks").update({"ai_status": "pending"}).eq("ai_status", "processing").execute()

    def reset_all(self):
        supabase.table("tracks").update({"ai_status": "pending"}).in_("ai_status", ["done", "error"]).execute()

    def save_embedding(self, track_id, embedding, model):
        supabase.table("track_embeddings").upsert(
            {"track_id": track_id, "embedding": embedding, "model": model},
            on_conflict="track_id",
        ).execute()

    def count_by_status(self):
        rows = supabase.table("tracks").select("ai_status").execute().data
        counts = {}
        for row in rows:
            counts[row["ai_status"]] = counts.get(row["ai_status"], 0) + 1
        return counts

    def search_by_embedding(self, embedding, limit):
        return supabase.rpc(
            "search_tracks_by_embedding",
            {"p_embedding": embedding, "p_limit": limit},
        ).execute().data

    def get_tracks_by_ids(self, track_ids):
        if not track_ids:
            return []
        return (
            supabase.table("tracks")
            .select("*, artists(id, name, avatar_url)")
            .in_("id", track_ids)
            .execute()
            .data
        )

    def get_all_embeddings(self):
        rows = supabase.table("track_embeddings").select("track_id, embedding").execute().data
        return [(row["track_id"], json.loads(row["embedding"])) for row in rows]

    def save_tags(self, track_id, mood_tags, ai_genre):
        supabase.table("tracks").update(
            {"mood_tags": mood_tags, "ai_genre": ai_genre}
        ).eq("id", track_id).execute()

    def get_embeddings_by_ids(self, track_ids):
        rows = (
            supabase.table("track_embeddings")
            .select("track_id, embedding")
            .in_("track_id", track_ids)
            .execute()
            .data
        )
        return {row["track_id"]: json.loads(row["embedding"]) for row in rows}