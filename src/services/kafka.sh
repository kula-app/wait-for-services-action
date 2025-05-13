#!/bin/bash

check_kafka() {
  echo " - Checking Kafka connection..."

  # Try kcat first, fall back to kafkacat if needed
  local kafka_cmd="kcat"
  if ! command -v kcat >/dev/null 2>&1; then
    kafka_cmd="kafkacat"
  fi

  echo "::debug::Checking Kafka TCP connection to $INPUT_HOST:$INPUT_PORT"
  if ! nc -z "$INPUT_HOST" "$INPUT_PORT"; then
    echo "::debug::Kafka TCP connection failed"
    return 1
  fi

  echo "::debug::Checking Kafka connection using $kafka_cmd"
  local output=$($kafka_cmd -b "$INPUT_HOST" -p "$INPUT_PORT" -L -t non_existent_topic 2>&1)
  local kafka_exit=$?
  echo "::debug::Kafka response: $output"
  echo "::debug::Kafka exit code: $kafka_exit"

  # Check for successful connection - must have exit code 0 OR contain "Metadata for" without error messages
  if { [ $kafka_exit -eq 0 ] && ! echo "$output" | grep -q "ERROR:"; } || { echo "$output" | grep -q "Metadata for" && ! echo "$output" | grep -q "ERROR:"; }; then
    echo " - ✓ Kafka is ready!"
    return 0
  fi

  echo "::debug::Kafka not ready yet."
  return 1
}
