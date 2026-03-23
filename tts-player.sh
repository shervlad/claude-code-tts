#!/bin/bash
# TTS queue player daemon
# Watches queue directory and plays segments in order
# SIGUSR1 = skip current segment, SIGUSR2/SIGTERM = stop all

QUEUE_DIR="/tmp/claude_tts_queue"
PID_FILE="/tmp/claude_tts_player.pid"
CURRENT_PID_FILE="/tmp/claude_tts_current.pid"

mkdir -p "$QUEUE_DIR"

# Save our PID
echo $$ > "$PID_FILE"

cleanup() {
  # Kill current playback if any
  if [ -f "$CURRENT_PID_FILE" ]; then
    kill -- -$(cat "$CURRENT_PID_FILE") 2>/dev/null
    rm -f "$CURRENT_PID_FILE"
  fi
  rm -f "$PID_FILE"
  rm -rf "$QUEUE_DIR"
  exit 0
}

skip() {
  # Kill only current playback; loop continues to next
  if [ -f "$CURRENT_PID_FILE" ]; then
    kill -- -$(cat "$CURRENT_PID_FILE") 2>/dev/null
    rm -f "$CURRENT_PID_FILE"
  fi
}

trap cleanup SIGTERM SIGUSR2 SIGINT
trap skip SIGUSR1

while true; do
  # Find the next queued segment (sorted by name)
  NEXT=$(ls "$QUEUE_DIR"/*.txt 2>/dev/null | sort | head -1)

  if [ -z "$NEXT" ]; then
    # No segments queued — wait a bit then check again
    sleep 0.2 &
    wait $!
    continue
  fi

  TEXT=$(cat "$NEXT")
  rm -f "$NEXT"

  if [ -z "$TEXT" ] || [ ${#TEXT} -lt 3 ]; then
    continue
  fi

  # Play this segment
  setsid bash -c '
    edge-tts --voice "en-US-AndrewNeural" --rate="+150%" --text "$1" --write-media - 2>/dev/null \
      | gst-launch-1.0 fdsrc ! mpegaudioparse ! mpg123audiodec ! audioconvert ! autoaudiosink 2>/dev/null
  ' _ "$TEXT" &
  PLAY_PID=$!
  echo "$PLAY_PID" > "$CURRENT_PID_FILE"

  # Wait for playback to finish (or be interrupted by signal)
  wait $PLAY_PID 2>/dev/null
  rm -f "$CURRENT_PID_FILE"
done
