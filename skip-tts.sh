#!/bin/bash
# Ctrl+Right: Skip to next TTS segment
PID_FILE="/tmp/claude_tts_player.pid"

if [ -f "$PID_FILE" ]; then
  kill -SIGUSR1 "$(cat "$PID_FILE")" 2>/dev/null
fi
