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
    echo '{"status":true,"result":{"id":124,"status":3,"status_text":"completed","stats":{"total":3,"statuses":{"1":2,"2":1}}}}'
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

  if ./enttrypoint.sh \
    --project-code TEST \
    --api-token test-token \
    --run-title "Test Run" \
    --case-ids 1,2,3; then

    echo "❌ Test failed: Script should have exited with error when tests failed"
    exit 1
  else
    echo "✅ Test passed: Script correctly exited with error when tests failed"
  fi
)

echo "All tests completed successfully!"