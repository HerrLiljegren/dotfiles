#!/bin/bash

# $1 = A search term (e.g., "Gemini" or the app_id)
# $@ = The full command to run
SEARCH_TERM="$1"
shift
LAUNCH_CMD="$@"

# Search Niri for a window where either the app_id OR the title 
# contains our search term (case-insensitive).
WINDOW_ID=$(niri msg -j windows | jq -r ".[] | select(
    (.app_id | ascii_downcase | contains(\"$SEARCH_TERM\" | ascii_downcase)) or 
    (.title  | ascii_downcase | contains(\"$SEARCH_TERM\" | ascii_downcase))
) | .id" | head -n 1)

if [ -n "$WINDOW_ID" ] && [ "$WINDOW_ID" != "null" ]; then
    niri msg action focus-window --id "$WINDOW_ID"
else
    # Execute the command in the background
    nohup $LAUNCH_CMD >/dev/null 2>&1 &
fi
