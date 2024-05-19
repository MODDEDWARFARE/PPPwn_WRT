#!/bin/sh

# Find all PIDs of processes containing 'myprocess' in their command line
pids=$(ps | grep '[./]pppwn' | grep -v grep | awk '{print $1}')

# Check if pids variable is empty
if [ -z "$pids" ]; then
  echo "---"
else
  # Kill each PID found
  echo "$pids" | xargs kill
  echo "Killed the following PIDs: $pids"
fi
