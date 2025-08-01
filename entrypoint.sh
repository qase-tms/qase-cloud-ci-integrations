#!/bin/bash

# Entrypoint script to map GitHub Action inputs to action.sh parameters

set -e

# Build the command with required parameters
CMD="/action.sh"
CMD+=" --project-code $INPUT_PROJECT_CODE"
CMD+=" --api-token '$INPUT_API_TOKEN'"
CMD+=" --run-title '$INPUT_RUN_TITLE'"

# Add optional parameters if provided
if [ -n "$INPUT_CASE_IDS" ]; then
  CMD+=" --case-ids $INPUT_CASE_IDS"
fi

if [ "$INPUT_INCLUDE_ALL_CASES" = "true" ]; then
  CMD+=" --include-all-cases"
fi

if [ -n "$INPUT_ENV_SLUG" ]; then
  CMD+=" --environment-slug $INPUT_ENV_SLUG"
fi

if [ -n "$INPUT_ENV_TITLE" ]; then
  CMD+=" --environment-title '$INPUT_ENV_TITLE'"
fi

if [ -n "$INPUT_ENV_HOST" ]; then
  CMD+=" --environment-host '$INPUT_ENV_HOST'"
fi

if [ -n "$INPUT_BROWSER" ]; then
  CMD+=" --browser $INPUT_BROWSER"
fi

if [ -n "$INPUT_TIMEOUT" ]; then
  CMD+=" --timeout $INPUT_TIMEOUT"
fi

if [ -n "$INPUT_POLL_INTERVAL" ]; then
  CMD+=" --poll-interval $INPUT_POLL_INTERVAL"
fi

echo "Executing: $CMD"
eval "$CMD"
