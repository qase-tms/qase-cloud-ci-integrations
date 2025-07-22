#!/bin/bash

# Qase Test Run Action
# This script creates a test run in Qase, waits for it to complete, and checks the final status

set -e

# Function to display usage information
usage() {
  echo "Usage: $0 --project-code CODE --api-token TOKEN --run-title TITLE [--case-ids IDS] [--environment-slug SLUG] [--include-all-cases] [--browser NAME] [--timeout SECONDS] [--poll-interval SECONDS]"
  echo ""
  echo "Required arguments:"
  echo "  --project-code CODE           Qase project code"
  echo "  --api-token TOKEN             Qase API token"
  echo "  --run-title TITLE             Title of the test run"
  echo ""
  echo "Optional arguments:"
  echo "  --browser NAME                Name of a browser to run autotests on (chromium, firefox, webkit)"
  echo "  --case-ids IDS                Comma-separated list of case IDs (e.g., '1,2,3')"
  echo "  --environment-slug SLUG       Environment SLUG to assign to the run"
  echo "  --environment-title TITLE     Environment title for creating new environment"
  echo "  --environment-host HOST       Environment host URL for creating new environment"
  echo "  --include-all-cases           Include all cases in the project"
  echo "  --timeout SECONDS             Maximum time to wait for run completion (default: 600)"
  echo "  --poll-interval SECONDS       Time between status checks (default: 10)"
  echo ""
  exit 1
}

# Default values
QASE_HOST="https://api.qase.io"
TIMEOUT=600
POLL_INTERVAL=10
INCLUDE_ALL_CASES=false
BROWSER="chromium"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-code)
      PROJECT_CODE="$2"
      shift 2
      ;;
    --browser)
      BROWSER="$2"
      shift 2
      ;;
    --api-token)
      API_TOKEN="$2"
      shift 2
      ;;
    --run-title)
      RUN_TITLE="$2"
      shift 2
      ;;
    --case-ids)
      CASE_IDS="$2"
      shift 2
      ;;
    --environment-slug)
      ENVIRONMENT_SLUG="$2"
      shift 2
      ;;
    --environment-title)
      ENVIRONMENT_TITLE="$2"
      shift 2
      ;;
    --environment-host)
      ENVIRONMENT_HOST="$2"
      shift 2
      ;;
    --include-all-cases)
      INCLUDE_ALL_CASES=true
      shift
      ;;
    --timeout)
      TIMEOUT="$2"
      shift 2
      ;;
    --poll-interval)
      POLL_INTERVAL="$2"
      shift 2
      ;;
    --help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# Validate required parameters
if [ -z "$PROJECT_CODE" ]; then
  echo "Error: Missing required PROJECT_CODE"
  usage
fi

if [ -z "$API_TOKEN" ]; then
  echo "Error: Missing required API_TOKEN"
  usage
fi

if [ -z "$RUN_TITLE" ]; then
  echo "Error: Missing required RUN_TITLE"
  usage
fi

# Prepare cases array for API request
if [ -n "$CASE_IDS" ]; then
  # Convert comma-separated list to JSON array
  CASES_JSON=$(echo "$CASE_IDS" | sed 's/,/,/g')
else
  CASES_JSON=""
fi

# Prepare configuration JSON
if [ -z "$BROWSER" ]; then
  echo "Error: Missing required BROWSER"
  usage
else
  CONFIGURATION="{\"browser\":\"$BROWSER\"}"
fi

# Handle environment creation/retrieval if environment parameters are provided
if [ -n "$ENVIRONMENT_SLUG" ] && [ -n "$ENVIRONMENT_TITLE" ]; then
  echo "Creating or retrieving environment: $ENVIRONMENT_TITLE ($ENVIRONMENT_SLUG)"
  
  # Validate that ENVIRONMENT_HOST is provided for environment creation
  if [ -z "$ENVIRONMENT_HOST" ]; then
    echo "Error: ENVIRONMENT_HOST is required when creating environments"
    exit 1
  fi
  
  # Build qasectl environment create command
  ENV_CMD="qasectl testops env create --project $PROJECT_CODE --token $API_TOKEN --title '$ENVIRONMENT_TITLE' --slug '$ENVIRONMENT_SLUG' --host '$ENVIRONMENT_HOST'"
  
  # Execute environment creation/retrieval
  echo "Executing: $ENV_CMD"
  if ! eval "$ENV_CMD"; then
    echo "Error: Failed to create or retrieve environment"
    exit 1
  fi
  
  echo "Environment $ENVIRONMENT_SLUG is ready"
fi

echo "Creating test run in Qase project: $PROJECT_CODE"

# Prepare the request payload using jq for cleaner JSON construction
REQUEST_DATA=$(jq -n \
  --arg title "$RUN_TITLE" \
  --argjson include_all_cases "$INCLUDE_ALL_CASES" \
  --argjson cloud_run_config "$CONFIGURATION" \
  --arg environment_slug "${ENVIRONMENT_SLUG:-}" \
  --arg cases_json "${CASES_JSON:-}" \
  '{
    title: $title,
    include_all_cases: $include_all_cases,
    cloud_run_config: $cloud_run_config,
    is_autotest: true,
    is_cloud: true
  } |
  if $environment_slug != "" then . + {environment_slug: $environment_slug} else . end |
  if $include_all_cases == false and $cases_json != "" then . + {cases: ($cases_json | split(",") | map(tonumber))} else . end'
)

# Create the test run
echo "Creating test run with the following configuration:"
echo "$REQUEST_DATA"
echo "Sending request to $QASE_HOST/v1/run/$PROJECT_CODE"

RESPONSE=$(curl -s -X POST "$QASE_HOST/v1/run/$PROJECT_CODE" \
  -H "Token: $API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Cookie: XDEBUG_SESSION=11235" \
  -d "$REQUEST_DATA")

if ! echo "$RESPONSE" | grep -q '"status":true'; then
  echo "Error creating test run:"
  echo "$RESPONSE"
  exit 1
fi

# Extract the run ID from the response
RUN_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$RUN_ID" ]; then
  echo "Error: Could not extract run ID from response"
  echo "$RESPONSE"
  exit 1
fi

echo "Test run created successfully with ID: $RUN_ID"
echo "Waiting for test run to complete (timeout: ${TIMEOUT}s, polling every ${POLL_INTERVAL}s)..."

ELAPSED=0
PROCESSED_COUNTER=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  # Get the current status of the run
  RUN_RESPONSE=$(curl -s "$QASE_HOST/v1/run/$PROJECT_CODE/$RUN_ID" \
    -H "Token: $API_TOKEN")

  if ! echo "$RUN_RESPONSE" | grep -q '"status":true'; then
    echo "Error checking run status:"
    echo "$RUN_RESPONSE"
    exit 1
  fi

  # Extract the status information
  STATUS=$(echo "$RUN_RESPONSE" | grep -o '"status":[0-9]*' | head -1 | cut -d':' -f2)
  STATUS_TEXT=$(echo "$RUN_RESPONSE" | grep -o '"status_text":"[^"]*"' | head -1 | cut -d'"' -f4)
  TOTAL=$(echo "$RUN_RESPONSE" | grep -o '"total":[0-9]*' | head -1 | cut -d':' -f2)
  STATUSES=$(echo "$RUN_RESPONSE" | grep -o '"statuses":{[^}]*}' | head -1)
  PASSED=$(echo "$STATUSES" | grep -o '"passed":[0-9]*' | cut -d':' -f2)

  # Sum all values in STATUSES except "untested"
  TOTAL_STATUSES=0
  UNTESTED=$(echo "$STATUSES" | grep -o '"untested":[0-9]*' | cut -d':' -f2)
  if [ -z "$UNTESTED" ]; then
    UNTESTED=0
  fi
  # Extract all numeric values from STATUSES
  VALUES=$(echo "$STATUSES" | grep -o ':[0-9]*' | cut -d':' -f2)
  for val in $VALUES; do
    TOTAL_STATUSES=$((TOTAL_STATUSES + val))
  done
  # Subtract the "untested" value
  if [ "$UNTESTED" -ne 0 ]; then
    TOTAL_STATUSES=$((TOTAL_STATUSES - UNTESTED))
  fi
  echo "Processed: $TOTAL_STATUSES from $TOTAL"

  if [ "$TOTAL_STATUSES" = "$TOTAL" ] || [ "$STATUS_TEXT" != "in_progress" ]; then
    echo "Response: $RUN_RESPONSE"

    if [ -z "$PASSED" ]; then
      PASSED=0
    fi

    echo "Test run completed. Total tests: $TOTAL, Passed tests: $PASSED"

    if [ "$TOTAL" = "$PASSED" ]; then
      echo "Test run finished successfully! ✅"
      exit 0
    else
      echo "Test run has failed! ❌"
      exit 1
    fi
  fi

  sleep $POLL_INTERVAL

  if [ $TOTAL_STATUSES -ne $PROCESSED_COUNTER ]; then
    PROCESSED_COUNTER=$TOTAL_STATUSES
    ELAPSED=0
  else
    ELAPSED=$((ELAPSED + POLL_INTERVAL))
  fi

  echo "Elapsed time: ${ELAPSED}s / ${TIMEOUT}s"
done

echo "Timeout reached. Test run did not complete within ${TIMEOUT} seconds."
exit 1