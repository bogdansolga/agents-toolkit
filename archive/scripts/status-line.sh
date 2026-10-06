#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract project name (basename of current directory)
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
project_name=$(basename "$current_dir")

# Get git branch (skip optional locks to avoid blocking)
git_branch=""
if git rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git -c core.fileMode=false -c core.preloadIndex=true symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  if [ -n "$git_branch" ]; then
    git_branch=" | 🌿 $git_branch"
  fi
fi

# Get model display name
model_name=$(echo "$input" | jq -r '.model.display_name')

# Get context window usage percentage
context_pct_used=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

# Output the status line
# Format: [🤖 Model] 📁 project | 🌿 branch | 📊 66%
printf "[🤖 %s] 📁 %s%s | 📊 %d%%" \
    "$model_name" "$project_name" "$git_branch" \
    "$context_pct_used"
