import re

import requests

from config import GROQ_API_KEY, GROQ_MODEL

GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
SYSTEM_PROMPT = (
    "You name daily music mixes in a streaming app. "
    "Reply with the name only: 2 to 4 English words, no quotes, no emojis, no punctuation at the end."
)


class NamingService:
    def name_mix(self, subtitle, artists, taken_names):
        if not GROQ_API_KEY:
            print("Groq key is not set, using subtitle as mix name")
            return subtitle
        prompt = f"Mix description: {subtitle}. Artists in the mix: {', '.join(artists)}. "
        if taken_names:
            prompt += f"Do not reuse these names: {', '.join(taken_names)}. "
        prompt += "Give one short evocative name for this mix."
        payload = {
            "model": GROQ_MODEL,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.8,
            "max_tokens": 300,
        }
        if GROQ_MODEL.startswith("openai/gpt-oss"):
            payload["reasoning_effort"] = "low"
        try:
            response = requests.post(
                GROQ_URL,
                headers={"Authorization": f"Bearer {GROQ_API_KEY}"},
                json=payload,
                timeout=15,
            )
            if response.status_code != 200:
                print(f"Groq error {response.status_code}: {response.text[:200]}")
                return subtitle
            name = response.json()["choices"][0]["message"].get("content") or ""
            name = re.sub(r"<think>.*?</think>", "", name, flags=re.DOTALL)
            name = re.sub(r'["“”«»*.!]', "", name).strip().split("\n")[0].strip()
            if not name or len(name) > 40 or name in taken_names:
                return subtitle
            return name
        except Exception as e:
            print(f"Groq error: {e}")
            return subtitle