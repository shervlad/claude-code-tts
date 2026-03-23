#!/bin/bash
# Escape: Stop all TTS playback and clear queue
PID_FILE="/tmp/claude_tts_player.pid"

if [ -f "$PID_FILE" ]; then
  kill -SIGTERM "$(cat "$PID_FILE")" 2>/dev/null
fi

# Clean up in case player didn't
rm -rf /tmp/claude_tts_queue
rm -f /tmp/claude_tts_player.pid /tmp/claude_tts_current.pid
