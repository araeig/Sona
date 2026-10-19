import time

import requests

from config import JAMENDO_CLIENT_ID

BASE_URL = "https://api.jamendo.com/v3.0"


class JamendoService:
    def _get(self, method, params, retries=3):
        params = {"client_id": JAMENDO_CLIENT_ID, "format": "json", **params}
        for attempt in range(1, retries + 1):
            try:
                response = requests.get(f"{BASE_URL}/{method}/", params=params, timeout=30)
                data = response.json()
                headers = data["headers"]
                if headers["status"] != "success":
                    print(f"Jamendo error: {headers['error_message']}")
                elif data["results"]:
                    return data["results"]
                else:
                    print(f"Jamendo empty response, attempt {attempt}")
            except Exception as e:
                print(f"Jamendo request error, attempt {attempt}: {e}")
            time.sleep(2)
        return []

    def get_genre_tracks(self, genre_tag, limit=100):
        return self._get("tracks", {
            "tags": genre_tag,
            "boost": "popularity_total",
            "limit": limit,
            "include": "musicinfo",
            "audioformat": "mp32",
            "imagesize": 500,
            "type": "single albumtrack",
        })

    def get_artists(self, artist_ids):
        return self._get("artists", {
            "id": " ".join(artist_ids),
            "limit": len(artist_ids),
        })

    def get_tracks_by_tag(self, tag, limit):
        return self._get("tracks", {
            "tags": tag,
            "boost": "popularity_total",
            "limit": limit,
            "include": "musicinfo",
            "audioformat": "mp32",
            "type": "single albumtrack",
        })