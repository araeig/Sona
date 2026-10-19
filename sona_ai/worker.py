import asyncio
import threading

from services.clap_service import MODEL_NAME, ClapService
from services.tagging_service import TaggingService
from services.tracks_service import TracksService

BATCH_SIZE = 10
IDLE_SECONDS = 30

clap = ClapService()
tagging = TaggingService(clap)
tracks_service = TracksService()
lock = threading.Lock()


def calibrate_tags():
    embeddings = [embedding for _, embedding in tracks_service.get_all_embeddings()]
    tagging.calibrate(embeddings)
    print(f"Tags calibrated on {len(embeddings)} tracks")


def process_track(track):
    with lock:
        try:
            tracks_service.set_status(track["id"], "processing")
            embedding = clap.embed_audio(track["audio_url"])
            tracks_service.save_embedding(track["id"], embedding, MODEL_NAME)
            moods, genre = tagging.tag(embedding)
            tracks_service.save_tags(track["id"], moods, genre)
            tracks_service.set_status(track["id"], "done")
            print(f"Processed: {track['title']} ({genre}; {', '.join(moods)})")
            return "done"
        except Exception as e:
            print(f"Process error ({track['title']}): {e}")
            tracks_service.set_status(track["id"], "error")
            return "error"


def retag_all():
    with lock:
        rows = tracks_service.get_all_embeddings()
        tagging.calibrate([embedding for _, embedding in rows])
        for track_id, embedding in rows:
            moods, genre = tagging.tag(embedding)
            tracks_service.save_tags(track_id, moods, genre)
        print(f"Retagged {len(rows)} tracks")
        return len(rows)


def process_pending():
    tracks = tracks_service.get_pending(BATCH_SIZE)
    for track in tracks:
        process_track(track)
    return len(tracks)


async def worker_loop():
    try:
        tracks_service.reset_stuck()
        await asyncio.to_thread(calibrate_tags)
    except Exception as e:
        print(f"Startup error: {e}")

    while True:
        try:
            processed = await asyncio.to_thread(process_pending)
        except Exception as e:
            print(f"Worker error: {e}")
            processed = 0
        if processed == 0:
            await asyncio.sleep(IDLE_SECONDS)