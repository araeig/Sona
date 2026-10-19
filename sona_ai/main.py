import asyncio
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from config import PORT
from db import supabase
from services.mix_service import MixService
from worker import clap, process_track, retag_all, tracks_service, worker_loop
from services.naming_service import NamingService

SEARCH_MIN_SIMILARITY = 0.4

mix_service = MixService(tracks_service, NamingService())


@asynccontextmanager
async def lifespan(app):
    task = asyncio.create_task(worker_loop())
    yield
    task.cancel()


app = FastAPI(title="Sona AI", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    try:
        response = (
            supabase.table("tracks")
            .select("id", count="exact")
            .limit(1)
            .execute()
        )
        return {"status": "ok", "tracks": response.count}
    except Exception as e:
        print(f"Health error: {e}")
        return {"status": "error", "detail": str(e)}


@app.get("/status")
def status():
    try:
        return tracks_service.count_by_status()
    except Exception as e:
        print(f"Status error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/process/{track_id}")
def process_one(track_id: str):
    try:
        track = tracks_service.get_track(track_id)
    except Exception as e:
        print(f"Process one error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    if track is None:
        raise HTTPException(status_code=404, detail="Track not found")
    return {"track_id": track_id, "status": process_track(track)}


@app.post("/reprocess-all")
def reprocess_all():
    try:
        tracks_service.reset_all()
        return {"status": "queued"}
    except Exception as e:
        print(f"Reprocess error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/retag-all")
def retag_all_tracks():
    try:
        return {"retagged": retag_all()}
    except Exception as e:
        print(f"Retag error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/search")
def search(q: str, limit: int = 10):
    query = q.strip()
    if not query:
        return []
    try:
        embedding = clap.embed_text(query)
        matches = tracks_service.search_by_embedding(embedding, limit)
        tracks = tracks_service.get_tracks_by_ids([m["track_id"] for m in matches])
        tracks_by_id = {track["id"]: track for track in tracks}
        result = []
        for match in matches:
            track = tracks_by_id.get(match["track_id"])
            if track and match["similarity"] >= SEARCH_MIN_SIMILARITY:
                track["similarity"] = round(match["similarity"], 3)
                result.append(track)
        return result
    except Exception as e:
        print(f"Search error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/mixes/{user_id}")
def build_mixes(user_id: str):
    try:
        return mix_service.build_for_user(user_id)
    except Exception as e:
        print(f"Mixes error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=PORT, reload=True)