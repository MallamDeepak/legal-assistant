from __future__ import annotations

import json
import os
import urllib.request
from typing import Optional


class LLMNotConfiguredError(RuntimeError):
    pass


def _get_openai_api_key() -> str:
    return os.getenv("OPENAI_API_KEY", "").strip()


def _get_openai_base_url() -> str:
    return os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1").rstrip("/")


def _get_openai_model() -> str:
    return os.getenv("OPENAI_MODEL", "gpt-4o-mini")


def chat_completion(system_prompt: str, user_prompt: str, *, temperature: float = 0.2, max_tokens: int = 900) -> str:
    """Call an OpenAI-compatible Chat Completions endpoint.

    Works with OpenAI and many local/OpenAI-compatible servers (vLLM, etc.)
    via OPENAI_BASE_URL.
    """
    api_key = _get_openai_api_key()
    if not api_key:
        raise LLMNotConfiguredError("OPENAI_API_KEY is not set")

    base_url = _get_openai_base_url()
    url = f"{base_url}/chat/completions"
    model = _get_openai_model()

    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
        "temperature": temperature,
        "max_tokens": max_tokens,
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            body = resp.read().decode("utf-8")
    except Exception as e:
        raise RuntimeError(f"LLM request failed: {e}")

    data = json.loads(body)
    choices = data.get("choices") or []
    if not choices:
        raise RuntimeError(f"LLM returned no choices: {data}")

    msg = choices[0].get("message") or {}
    content: Optional[str] = msg.get("content")
    if not content:
        raise RuntimeError(f"LLM returned empty content: {data}")
    return content
