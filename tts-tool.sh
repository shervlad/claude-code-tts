#!/bin/bash
# PostToolUse hook: reads new assistant text from transcript + speaks tool summary

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -c '.tool_input // {}')

POS_FILE="/tmp/claude_tts_pos"
SPEAK="/home/vladseremet/.claude/hooks/tts-speak.sh"

# --- Extract new assistant text blocks from transcript ---
CURRENT_LINES=$(wc -l < "$TRANSCRIPT" 2>/dev/null || echo 0)
LAST_POS=$(cat "$POS_FILE" 2>/dev/null || echo 0)

if [ "$CURRENT_LINES" -gt "$LAST_POS" ]; then
  # Get new assistant text blocks since last check
  NEW_TEXT=$(tail -n +"$((LAST_POS + 1))" "$TRANSCRIPT" 2>/dev/null \
    | jq -r 'select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text // empty' 2>/dev/null \
    | tr '\n' ' ')
fi

# Update position
echo "$CURRENT_LINES" > "$POS_FILE"

# --- Generate elegant tool summary ---
case "$TOOL_NAME" in
  Read)
    FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' | sed 's|.*/||')
    SUMMARY="Reading $FILE"
    ;;
  Edit)
    FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' | sed 's|.*/||')
    SUMMARY="Editing $FILE"
    ;;
  Write)
    FILE=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' | sed 's|.*/||')
    SUMMARY="Writing $FILE"
    ;;
  Bash)
    DESC=$(echo "$TOOL_INPUT" | jq -r '.description // empty')
    if [ -n "$DESC" ]; then
      SUMMARY="$DESC"
    else
      CMD=$(echo "$TOOL_INPUT" | jq -r '.command // empty' | head -c 80)
      SUMMARY="Running command: $CMD"
    fi
    ;;
  Grep)
    PATTERN=$(echo "$TOOL_INPUT" | jq -r '.pattern // empty')
    SUMMARY="Searching for $PATTERN"
    ;;
  Glob)
    PATTERN=$(echo "$TOOL_INPUT" | jq -r '.pattern // empty')
    SUMMARY="Finding files matching $PATTERN"
    ;;
  Agent)
    DESC=$(echo "$TOOL_INPUT" | jq -r '.description // empty')
    SUMMARY="Delegating: $DESC"
    ;;
  AskUserQuestion)
    SUMMARY=""
    ;;
  *)
    SUMMARY="Using $TOOL_NAME"
    ;;
esac

# --- Combine and speak ---
FULL_TEXT=""
if [ -n "$NEW_TEXT" ]; then
  FULL_TEXT="$NEW_TEXT"
fi
if [ -n "$SUMMARY" ]; then
  FULL_TEXT="$FULL_TEXT ... $SUMMARY"
fi

if [ -n "$FULL_TEXT" ]; then
  "$SPEAK" "$FULL_TEXT"
fi

exit 0
