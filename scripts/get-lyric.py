#!/usr/bin/env python3
"""
get-lyric.py – fetch the current synced-lyric line for a given MPRIS player.

Usage:
    python3 get-lyric.py [--player PLAYER_NAME]

Output: prints the current lyric line (or an empty line when unavailable).
Lyrics are cached in ~/.cache/my-lyric/ to avoid repeated API calls.
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import urllib.parse
import urllib.request

CACHE_DIR = os.path.expanduser("~/.cache/my-lyric")
NO_LYRICS_SENTINEL = "# NO_LYRICS\n"


# ---------------------------------------------------------------------------
# playerctl helpers
# ---------------------------------------------------------------------------

def _run(cmd: list[str]) -> str | None:
    """Run a command and return stripped stdout, or None on failure."""
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=3)
        return result.stdout.strip() if result.returncode == 0 else None
    except Exception:
        return None


def get_track_info(player: str) -> dict | None:
    """Return a dict with title/artist/album/duration/position, or None."""
    title = _run(["playerctl", f"--player={player}", "metadata", "xesam:title"])
    artist = _run(["playerctl", f"--player={player}", "metadata", "xesam:artist"])
    if not title or not artist:
        return None

    album = _run(["playerctl", f"--player={player}", "metadata", "xesam:album"]) or ""
    duration_us = _run(["playerctl", f"--player={player}", "metadata", "mpris:length"])
    position_str = _run(["playerctl", f"--player={player}", "position"])

    duration_s: float | None = None
    if duration_us and duration_us.isdigit():
        duration_s = int(duration_us) / 1_000_000

    position_s = 0.0
    if position_str:
        try:
            position_s = float(position_str)
        except ValueError:
            pass

    return {
        "title": title,
        "artist": artist,
        "album": album,
        "duration": duration_s,
        "position": position_s,
    }


# ---------------------------------------------------------------------------
# LRCLIB
# ---------------------------------------------------------------------------

def fetch_lyrics(title: str, artist: str, album: str, duration: float | None) -> str | None:
    """Query LRCLIB and return syncedLyrics (or plainLyrics) string, or None."""
    params: dict[str, str | int] = {
        "track_name": title,
        "artist_name": artist,
    }
    if album:
        params["album_name"] = album
    if duration is not None:
        params["duration"] = int(duration)

    url = "https://lrclib.net/api/get?" + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "my-lyric/0.1.0 (github.com/Akuma-real/my-lyric)"})
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read())
            return data.get("syncedLyrics") or data.get("plainLyrics") or None
    except Exception:
        return None


# ---------------------------------------------------------------------------
# LRC parser
# ---------------------------------------------------------------------------

_LRC_RE = re.compile(r"\[(\d+):(\d+(?:\.\d+)?)\](.*)")


def parse_lrc(lrc_text: str) -> list[tuple[float, str]]:
    """Parse LRC text into a sorted list of (time_seconds, lyric_line)."""
    lines: list[tuple[float, str]] = []
    for raw_line in lrc_text.splitlines():
        m = _LRC_RE.match(raw_line)
        if m:
            minutes = int(m.group(1))
            seconds = float(m.group(2))
            text = m.group(3).strip()
            lines.append((minutes * 60 + seconds, text))
    lines.sort(key=lambda x: x[0])
    return lines


def get_current_line(lines: list[tuple[float, str]], position: float) -> str:
    """Return the lyric line whose timestamp is <= position (last such line)."""
    current = ""
    for time_s, text in lines:
        if time_s <= position:
            current = text
        else:
            break
    return current


# ---------------------------------------------------------------------------
# Cache helpers
# ---------------------------------------------------------------------------

def _cache_path(title: str, artist: str) -> str:
    key = hashlib.sha256(f"{artist}\x00{title}".encode()).hexdigest()
    return os.path.join(CACHE_DIR, key + ".lrc")


def _load_cache(path: str) -> str | None:
    """Return cached lyrics string, empty string for NO_LYRICS, or None if not cached."""
    if not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as fh:
        content = fh.read()
    if content == NO_LYRICS_SENTINEL:
        return ""  # cached "no lyrics" – caller should print blank line
    return content


def _save_cache(path: str, lyrics: str | None) -> None:
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(lyrics if lyrics else NO_LYRICS_SENTINEL)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Print the current lyric line.")
    parser.add_argument("--player", default="splayer", help="MPRIS player name")
    args = parser.parse_args()

    os.makedirs(CACHE_DIR, exist_ok=True)

    info = get_track_info(args.player)
    if not info:
        print("")
        return

    cache_file = _cache_path(info["title"], info["artist"])
    lrc_text = _load_cache(cache_file)

    if lrc_text is None:
        # Not cached yet – fetch from LRCLIB
        lrc_text = fetch_lyrics(info["title"], info["artist"], info["album"], info["duration"])
        _save_cache(cache_file, lrc_text)

    if not lrc_text:
        print("")
        return

    lines = parse_lrc(lrc_text)
    if not lines:
        # Plain-text lyrics (no timestamps) – show first non-empty line
        first = next((l for l in lrc_text.splitlines() if l.strip()), "")
        print(first)
        return

    print(get_current_line(lines, info["position"]))


if __name__ == "__main__":
    main()
