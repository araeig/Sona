from collections import Counter
from datetime import datetime, timedelta, timezone

import numpy as np
from sklearn.cluster import KMeans

from db import supabase

MIN_HISTORY_TRACKS = 8
MAX_MIXES = 4
TRACKS_PER_MIX = 20
HISTORY_TRACKS_PER_MIX = 8
HISTORY_DAYS = 60


class MixService:
    def __init__(self, tracks_service, naming_service):
        self.tracks_service = tracks_service
        self.naming_service = naming_service

    def _history_track_ids(self, user_id):
        since = (datetime.now(timezone.utc) - timedelta(days=HISTORY_DAYS)).isoformat()
        rows = (
            supabase.table("play_history")
            .select("track_id")
            .eq("user_id", user_id)
            .gte("played_at", since)
            .order("played_at", desc=True)
            .execute()
            .data
        )
        return list(dict.fromkeys(row["track_id"] for row in rows))

    def _subtitle(self, tracks):
        genres = Counter(t["ai_genre"] for t in tracks if t.get("ai_genre"))
        moods = Counter(m for t in tracks for m in t.get("mood_tags") or [])
        genre = genres.most_common(1)[0][0] if genres else "Mixed"
        top_moods = [mood for mood, _ in moods.most_common(2)]
        return f"{genre} · {', '.join(top_moods)}" if top_moods else genre

    def _interleave(self, familiar, new):
        result = []
        while familiar or new:
            if familiar:
                result.append(familiar.pop(0))
            for _ in range(2):
                if new:
                    result.append(new.pop(0))
        return result

    def _save(self, user_id, mixes):
        supabase.table("daily_mixes").delete().eq("user_id", user_id).execute()
        for position, mix in enumerate(mixes, start=1):
            row = (
                supabase.table("daily_mixes")
                .insert({
                    "user_id": user_id,
                    "position": position,
                    "name": mix["name"],
                    "subtitle": mix["subtitle"],
                    "cover_url": mix["cover_url"],
                })
                .execute()
                .data[0]
            )
            supabase.table("daily_mix_tracks").insert([
                {"mix_id": row["id"], "track_id": track_id, "position": index}
                for index, track_id in enumerate(mix["track_ids"], start=1)
            ]).execute()

    def build_for_user(self, user_id):
        history_ids = self._history_track_ids(user_id)
        embeddings = self.tracks_service.get_embeddings_by_ids(history_ids) if history_ids  else {}
        ids = [track_id for track_id in history_ids if track_id in embeddings]
        if len(ids) < MIN_HISTORY_TRACKS:
            return {"status": "not_enough_history", "history_tracks": len(ids)}

        matrix = np.array([embeddings[track_id] for track_id in ids])
        clusters = max(2, min(MAX_MIXES, len(ids) // 4))
        kmeans = KMeans(n_clusters=clusters, n_init=10, random_state=0).fit(matrix)

        used = set(ids)
        mixes = []
        for cluster in range(clusters):
            members = np.where(kmeans.labels_ == cluster)[0]
            center = kmeans.cluster_centers_[cluster]
            center = center / np.linalg.norm(center)
            ranked = sorted(members, key=lambda i: -float(matrix[i] @ center))
            familiar = [ids[i] for i in ranked[:HISTORY_TRACKS_PER_MIX]]

            new = []
            for match in self.tracks_service.search_by_embedding(center.tolist(), 60):
                if len(familiar) + len(new) >= TRACKS_PER_MIX:
                    break
                if match["track_id"] not in used:
                    new.append(match["track_id"])
                    used.add(match["track_id"])

            mixes.append({
                "track_ids": self._interleave(familiar, new),
                "size": len(members),
            })

        all_ids = list({track_id for mix in mixes for track_id in mix["track_ids"]})
        meta = {track["id"]: track for track in self.tracks_service.get_tracks_by_ids(all_ids)}
        taken_names = []
        for mix in mixes:
            mix_tracks = [meta[track_id] for track_id in mix["track_ids"] if track_id in meta]
            mix["subtitle"] = self._subtitle(mix_tracks)
            artists = list(dict.fromkeys(
                t["artists"]["name"] for t in mix_tracks if t.get("artists")
            ))[:4]
            mix["name"] = self.naming_service.name_mix(mix["subtitle"], artists, taken_names)
            taken_names.append(mix["name"])
            mix["cover_url"] = mix_tracks[0].get("cover_url") if mix_tracks else None

        mixes.sort(key=lambda mix: -mix["size"])
        self._save(user_id, mixes)
        return {
            "status": "ok",
            "history_tracks": len(ids),
            "mixes": [{"name": mix["name"], "tracks": len(mix["track_ids"])} for mix in mixes],
        }
