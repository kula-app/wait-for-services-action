#!/bin/bash

check_mongodb() {
  echo " - Checking MongoDB connection..."

  echo "::debug::Checking MongoDB TCP connection to $INPUT_HOST:$INPUT_PORT"
  if ! nc -z "$INPUT_HOST" "$INPUT_PORT"; then
    echo "::debug::MongoDB TCP connection failed"
    return 1
  fi

  echo "::debug::Checking MongoDB connection using mongosh"
  local output=$(mongosh --host "$INPUT_HOST" --port "$INPUT_PORT" --eval "db.runCommand({ping:1})" 2>&1)
  echo "::debug::MongoDB response: $output"

  if echo "$output" | grep -q '"ok" : 1' || echo "$output" | grep -q "ok: 1"; then
    echo " - ✓ MongoDB is ready!"
    return 0
  fi

  echo "::debug::MongoDB not ready yet."
  return 1
}
