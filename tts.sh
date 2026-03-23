#!/bin/bash
# Stop hook: reads any remaining assistant text from transcript

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // empty')

POS_FILE="/tmp/claude_tts_pos"
SPEAK="/home/vladseremet/.claude/hooks/tts-speak.sh"

# --- Extract new assistant text blocks from transcript ---
CURRENT_LINES=$(wc -l < "$TRANSCRIPT" 2>/dev/null || echo 0)
LAST_POS=$(cat "$POS_FILE" 2>/dev/null || echo 0)

TEXT=""
if [ "$CURRENT_LINES" -gt "$LAST_POS" ]; then
  TEXT=$(tail -n +"$((LAST_POS + 1))" "$TRANSCRIPT" 2>/dev/null \
    | jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text // empty' 2>/dev/null \
    | tr '\n' ' ')
fi

# Fallback to last_assistant_message if transcript parsing found nothing
if [ -z "$TEXT" ]; then
  TEXT="$LAST_MSG"
fi

# Update position (keep file so next turn doesn't restart from 0)
echo "$CURRENT_LINES" > "$POS_FILE"

if [ -n "$TEXT" ] && [ ${#TEXT} -ge 5 ]; then
  "$SPEAK" "$TEXT"
fi

exit 0
