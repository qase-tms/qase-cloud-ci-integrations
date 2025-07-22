#!/bin/bash


set -e

echo "Testing qase-run.sh with mock data..."

mock_curl() {
  local url=""
  for arg in "$@"; do
    if [[ "$arg" == https://* ]]; then
      url="$arg"
      break
    fi
  done

  if [[ "$url" == *"/run/TEST" && ! "$url" == *"/run/TEST/"* ]]; then
    echo '{"status":true,"result":{"id":123}}'
  elif [[ "$url" == *"/run/TEST/123"* ]]; then
    echo '{"status":true,"result":{"id":123,"status":3,"status_text":"completed","stats":{"total":3,"statuses":{"passed":3}}}}'
  else
    echo "Unexpected curl call: $@" >&2
    exit 1
  fi
}

export -f mock_curl

echo "Running test with all tests passing..."
(
  function curl { mock_curl "$@"; }
  export -f curl

  ./action.sh \
    --project-code TEST \
    --api-token test-token \
    --run-title "Test Run" \
    --case-ids 1,2,3

  echo "✅ Test passed: Script exited with success when all tests passed"
)

mock_curl_failing() {
  local url=""
  for arg in "$@"; do
    if [[ "$arg" == https://* ]]; then
      url="$arg"
      break
    fi
  done

  if [[ "$url" == *"/run/TEST" && ! "$url" == *"/run/TEST/"* ]]; then
    echo '{"status":true,"result":{"id":124}}'
  elif [[ "$url" == *"/run/TEST/124"* ]]; then
    echo '{"status":true,"result":{"id":124,"status":3,"status_text":"completed","stats":{"total":3,"statuses":{"passed":1,"failed":2}}}}'
  else
    echo "Unexpected curl call: $@" >&2
    exit 1
  fi
}

export -f mock_curl_failing

echo "Running test with some tests failing..."
(
  function curl { mock_curl_failing "$@"; }
  export -f curl

  # Capture both stdout and stderr, and the exit code
  OUTPUT=$(./action.sh \
    --project-code TEST \
    --api-token test-token \
    --run-title "Test Run" \
    --case-ids 1,2,3 2>&1) || EXIT_CODE=$?

  # Check if script failed as expected
  if [ "${EXIT_CODE:-0}" -eq 0 ]; then
    echo "❌ Test failed: Script should have exited with error when tests failed"
    exit 1
  fi

  # Check if the specific failure message is present
  if echo "$OUTPUT" | grep -q "Test run has failed! ❌"; then
    echo "✅ Test passed: Script correctly exited with error and showed failure message"
  else
    echo "❌ Test failed: Script exited with error but didn't show expected failure message"
    echo "Actual output:"
    echo "$OUTPUT"
    exit 1
  fi
)

echo "All tests completed successfully!"