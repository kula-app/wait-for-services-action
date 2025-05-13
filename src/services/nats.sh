#!/bin/bash

check_nats() {
  echo " - Checking NATS connection..."

  echo "::debug::Checking NATS TCP connection to $INPUT_HOST:$INPUT_PORT"
  if ! nc -z "$INPUT_HOST" "$INPUT_PORT"; then
    echo "::debug::NATS TCP connection failed"
    return 1
  fi

  echo "::debug::Checking NATS HTTP connection using curl"
  local http_output=$(timeout 5 curl -s "http://$INPUT_HOST:$INPUT_PORT" 2>&1)
  local curl_exit=$?
  echo "::debug::NATS HTTP response: $http_output"
  echo "::debug::curl exit code: $curl_exit"

  # Even if curl fails with a specific HTTP error, the service might be up
  if [ $curl_exit -eq 0 ] || [ $curl_exit -eq 22 ]; then
    echo " - ✓ NATS is ready!"
    return 0
  fi

  echo "::debug::NATS not ready yet."
  return 1
}
