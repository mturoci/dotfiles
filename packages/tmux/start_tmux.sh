#!/bin/bash

# Try to attach to a tmux session
output=$(tmux a 2>&1)

# Check if the output contains "no sessions"
if [[ $output == *"no sessions"* ]]; then
  # If no sessions, create a new one
  tmux new
fi
