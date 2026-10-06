#!/bin/bash

# Toggle global commands visibility for presentations
# Run once to hide, run again to restore

COMMANDS=~/.claude/commands
COMMANDS_TEMP=~/.claude/commands-temp

if [ -e "$COMMANDS_TEMP" ] || [ -L "$COMMANDS_TEMP" ]; then
    mv "$COMMANDS_TEMP" "$COMMANDS"
    echo "✓ Global commands restored"
elif [ -e "$COMMANDS" ] || [ -L "$COMMANDS" ]; then
    mv "$COMMANDS" "$COMMANDS_TEMP"
    echo "✓ Global commands hidden (presentation mode)"
else
    echo "✗ No commands folder found"
    exit 1
fi
