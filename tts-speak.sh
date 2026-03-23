#!/bin/bash
# Enqueue text to be spoken by the TTS player
# Usage: tts-speak.sh "text to speak"

MESSAGE="$1"
QUEUE_DIR="/tmp/claude_tts_queue"
PID_FILE="/tmp/claude_tts_player.pid"
PLAYER="/home/vladseremet/.claude/hooks/tts-player.sh"

if [ -z "$MESSAGE" ] || [ ${#MESSAGE} -lt 3 ]; then
  exit 0
fi

mkdir -p "$QUEUE_DIR"

# Enqueue the text with a timestamp-based filename for ordering
SEQ=$(date +%s%N)
echo "$MESSAGE" > "$QUEUE_DIR/${SEQ}.txt"

# Start the player if not already running
if [ -f "$PID_FILE" ]; then
  PLAYER_PID=$(cat "$PID_FILE")
  if kill -0 "$PLAYER_PID" 2>/dev/null; then
    exit 0
  fi
fi

# Launch player in background
nohup "$PLAYER" >/dev/null 2>&1 &
