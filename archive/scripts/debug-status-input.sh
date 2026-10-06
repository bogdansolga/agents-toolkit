#!/bin/bash

# Debug script to see what data is available in the status line input
# Run this temporarily as your status line to see the JSON structure

input=$(cat)

# Save the full input to a file for inspection
echo "$input" | jq '.' > /tmp/status-line-input-debug.json

# Show what we have
echo "Input saved to: /tmp/status-line-input-debug.json"

# Try to find rate limit related fields
echo "Searching for rate_limits, budget, session, weekly fields..."
echo "$input" | jq 'paths(scalars) as $p | select($p | join(".") | test("rate|budget|session|week"; "i")) | {path: $p, value: getpath($p)}'

# Show the basic info we can display
model=$(echo "$input" | jq -r '.model.display_name')
echo "Model: $model"
