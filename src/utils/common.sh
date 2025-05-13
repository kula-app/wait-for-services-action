#!/bin/bash

# Function to check if a TCP port is open
check_tcp_port() {
  echo "::debug::Checking TCP connectivity to $INPUT_HOST:$INPUT_PORT"
  local output=$(nc -z -v "$INPUT_HOST" "$INPUT_PORT" 2>&1)
  local exit_code=$?
  echo "::debug::TCP check output: $output"
  echo "::debug::TCP check exit code: $exit_code"
  return $exit_code
}

# Set GitHub Actions status
indicate_status() {
  local exit_code=$1

  if [ $exit_code -eq 0 ]; then
    echo "::group::Service status check summary"
    echo " - Service type: $INPUT_TYPE"
    echo " - Host: $INPUT_HOST"
    echo " - Port: $INPUT_PORT"
    echo " - Status: ✅ READY"
    echo "::endgroup::"
  else
    echo "::group::Service status check summary"
    echo " - Service type: $INPUT_TYPE"
    echo " - Host: $INPUT_HOST"
    echo " - Port: $INPUT_PORT"
    echo " - Status: ❌ FAILED"
    echo " - Last error: Service did not become ready within specified time"
    echo "::endgroup::"
  fi

  return $exit_code
}

# Validate inputs
validate_inputs() {
  echo "::group::Validating inputs"

  local validation_failed=false

  if [ -z "$INPUT_TYPE" ]; then
    echo "::error::Missing required input: type"
    validation_failed=true
  else
    echo " - ✓ Service type: $INPUT_TYPE"
  fi

  if [ -z "$INPUT_HOST" ]; then
    echo "::error::Missing required input: host"
    validation_failed=true
  else
    echo " - ✓ Host: $INPUT_HOST"
  fi

  if [ -z "$INPUT_PORT" ]; then
    echo "::error::Missing required input: port"
    validation_failed=true
  else
    echo " - ✓ Port: $INPUT_PORT"
  fi

  # Service-specific validations
  if [ "$INPUT_TYPE" = "postgres" ]; then
    if [ -n "$INPUT_USERNAME" ]; then
      echo " - ✓ Postgres username: $INPUT_USERNAME"
    fi

    if [ -n "$INPUT_DATABASE" ]; then
      echo " - ✓ Postgres database: $INPUT_DATABASE"
    fi
  fi

  if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]]; then
    echo "::error::Invalid timeout value: $TIMEOUT. Must be a number."
    validation_failed=true
  else
    echo " - ✓ Timeout: $TIMEOUT seconds"
  fi

  if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]]; then
    echo "::error::Invalid interval value: $INTERVAL. Must be a number."
    validation_failed=true
  else
    echo " - ✓ Check interval: $INTERVAL seconds"
  fi

  if [[ "$WAIT_INDEFINITELY" != "true" && "$WAIT_INDEFINITELY" != "false" ]]; then
    echo "::error::Invalid wait-indefinitely value: $WAIT_INDEFINITELY. Must be 'true' or 'false'."
    validation_failed=true
  else
    echo " - ✓ Wait indefinitely: $WAIT_INDEFINITELY"
  fi

  echo "::endgroup::"

  if [ "$validation_failed" = true ]; then
    exit 1
  fi
}
