# Claude Code TTS Hooks

Automatic text-to-speech for Claude Code responses using Microsoft Edge's neural voices.

## Features

- Natural-sounding voice (Microsoft Edge Neural TTS)
- Streams audio for instant playback — no waiting for full generation
- Reads all assistant text blocks, not just the final one
- Elegant summaries for tool uses (e.g., "Editing config.yaml", "Searching for pattern")
- Queue-based playback with skip and stop controls

## Controls

| Shortcut | Action |
|---|---|
| **Ctrl+Right** | Skip current segment, play next |
| **Escape** | Stop all TTS and clear queue |

## Dependencies

- [edge-tts](https://github.com/rany2/edge-tts) — `pip install edge-tts`
- GStreamer — `gst-launch-1.0` with mp3 decoding support
- jq — JSON parsing

## Files

| File | Purpose |
|---|---|
| `tts.sh` | **Stop hook** — speaks remaining assistant text when Claude finishes |
| `tts-tool.sh` | **PostToolUse hook** — speaks new assistant text + tool summary after each tool use |
| `tts-speak.sh` | Enqueues text to the TTS player |
| `tts-player.sh` | Background queue player daemon |
| `skip-tts.sh` | Skips current TTS segment (Ctrl+Right) |
| `kill-tts.sh` | Stops all TTS playback (Escape) |

## Setup

### 1. Install dependencies

```bash
pip install edge-tts
# GStreamer and jq are usually pre-installed on Ubuntu/Debian
```

### 2. Configure Claude Code hooks

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/tts-tool.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/tts.sh"
          }
        ]
      }
    ]
  }
}
```

### 3. Set up keyboard shortcuts (GNOME)

```bash
PATH_BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['$PATH_BASE/custom0/', '$PATH_BASE/custom1/']"

# Ctrl+Right → skip
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH_BASE/custom0/ \
  name "Skip Claude TTS"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH_BASE/custom0/ \
  command "~/.claude/hooks/skip-tts.sh"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH_BASE/custom0/ \
  binding "<Ctrl>Right"

# Escape → stop
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH_BASE/custom1/ \
  name "Stop Claude TTS"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH_BASE/custom1/ \
  command "~/.claude/hooks/kill-tts.sh"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$PATH_BASE/custom1/ \
  binding "Escape"
```

## Customization

Change the voice or speed in `tts-speak.sh` / `tts-player.sh`:

```bash
# Voice options: en-US-AndrewNeural, en-US-AriaNeural, en-US-AvaNeural, etc.
# List all: edge-tts --list-voices
edge-tts --voice "en-US-AndrewNeural" --rate="+30%"
```
