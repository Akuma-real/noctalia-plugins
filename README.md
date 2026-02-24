# my-lyric

A [Noctalia](https://github.com/noctalia-dev/noctalia) bar-widget plugin that displays the **current synced lyric line** for whatever is playing in your MPRIS-compatible music player (tested with SPlayer).

---

## How it works

```
Timer (every refreshMs ms)
  └─► Process  ──runs──►  scripts/get-lyric.py
                                │
                         playerctl metadata
                         (title / artist / position)
                                │
                         LRCLIB API  ──►  syncedLyrics
                         (cached in ~/.cache/my-lyric/)
                                │
                         parse LRC timestamps
                                │
                         print current line
                                │
                  ◄── stdout ── BarWidget shows text
```

The helper script (`scripts/get-lyric.py`) is called once per refresh interval. It:

1. Reads the current track title, artist, album, playback position and duration via `playerctl`.
2. Looks up a local cache (`~/.cache/my-lyric/<md5>.lrc`). On a cache miss it queries the [LRCLIB](https://lrclib.net/) public API.
3. Parses the LRC timestamp format and finds the line whose timestamp ≤ current position.
4. Prints that line to stdout (empty line when nothing is playing or lyrics are unavailable).

---

## Requirements

| Tool | Purpose |
|---|---|
| `playerctl` | Read MPRIS metadata & position |
| `python3` | Run the helper script |
| Noctalia ≥ 3.6.0 | Plugin host |

---

## Installation

### Option A – Custom plugin source (recommended)

1. In Noctalia open **Plugins → Sources → Add custom repository**.
2. Enter:
   ```
   https://raw.githubusercontent.com/Akuma-real/my-lyric/main/registry.json
   ```
3. Find **Lyrics (SPlayer)** in the plugin list and install it.

### Option B – Manual

```bash
# Clone into the Noctalia plugins directory (path may differ by your setup)
git clone https://github.com/Akuma-real/my-lyric \
    ~/.local/share/noctalia/plugins/my-lyric
```

Then reload Noctalia or enable the plugin from **Plugins**.

---

## Settings

| Setting | Default | Description |
|---|---|---|
| `playerName` | `splayer` | Name reported by `playerctl` (e.g. `mpv`, `vlc`) |
| `refreshMs` | `1000` | How often (ms) the widget polls for the current line |

Change them in **Plugins → Lyrics (SPlayer) → Settings**.

---

## Plugin structure

```
my-lyric/
├── manifest.json       # Plugin metadata & default settings
├── BarWidget.qml       # Bar widget: Timer + Process → display lyric
├── Settings.qml        # Settings panel (playerName, refreshMs)
├── scripts/
│   └── get-lyric.py    # Lyrics fetcher / LRC parser helper script
└── registry.json       # GitHub custom-source registry entry
```

---

## License

MIT