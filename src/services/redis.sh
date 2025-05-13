#!/bin/bash

check_redis() {
  echo " - Checking Redis connection..."

  echo "::debug::Checking Redis TCP connection to $INPUT_HOST:$INPUT_PORT"
  if ! nc -z "$INPUT_HOST" "$INPUT_PORT"; then
    echo "::debug::Redis TCP connection failed"
    return 1
  fi

  local output
  local redis_exit

  echo "::debug::Checking Redis connection using redis-cli"
  if [ -z "$INPUT_PASSWORD" ]; then
    output=$(redis-cli -h "$INPUT_HOST" -p "$INPUT_PORT" ping 2>&1)
    redis_exit=$?
    echo "::debug::Redis PING response: $output"
    echo "::debug::Redis exit code: $redis_exit"

    # Check if authentication is required but no password was provided
    if echo "$output" | grep -q "NOAUTH Authentication required" && [ -z "$INPUT_PASSWORD" ]; then
      echo "::error::Redis requires authentication, but no password was provided."
      return 1
    fi
  else
    output=$(redis-cli -h "$INPUT_HOST" -p "$INPUT_PORT" -a "$INPUT_PASSWORD" ping 2>&1)
    redis_exit=$?
    echo "::debug::Redis PING response: $output"
    echo "::debug::Redis exit code: $redis_exit"
  fi

  if echo "$output" | grep -q "PONG"; then
    echo " - ✓ Redis is ready!"
    return 0
  fi

  echo "::debug::Redis not ready yet."
  return 1
}
