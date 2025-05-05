#!/bin/bash
set -e

# Set defaults
TIMEOUT=${INPUT_TIMEOUT:-20}
INTERVAL=${INPUT_INTERVAL:-1}
WAIT_INDEFINITELY=${INPUT_WAIT_INDEFINITELY:-false}

# Function to check if a TCP port is open
check_tcp_port() {
  echo "::debug::Checking TCP connectivity to $INPUT_HOST:$INPUT_PORT"
  local output=$(nc -z -v "$INPUT_HOST" "$INPUT_PORT" 2>&1)
  local exit_code=$?
  echo "::debug::TCP check output: $output"
  echo "::debug::TCP check exit code: $exit_code"
  return $exit_code
}

# Wait for service to be ready
wait_for_service() {
  local start_time=$(date +%s)
  local elapsed=0

  echo "::group::Waiting for $INPUT_TYPE service to be ready"

  # First check if we can reach the host at all
  if ! check_tcp_port; then
    echo "::warning::Initial TCP connection to $INPUT_HOST:$INPUT_PORT failed. Will keep trying..."
  else
    echo " - ✓ Initial TCP connection to $INPUT_HOST:$INPUT_PORT successful"
  fi

  while true; do
    # Check if service is ready based on type
    case "$INPUT_TYPE" in
    "mongodb")
      echo " - Checking MongoDB connection..."
      local output=$(mongosh --host "$INPUT_HOST" --port "$INPUT_PORT" --eval "db.runCommand({ping:1})" 2>&1)
      echo "::debug::MongoDB response: $output"

      if echo "$output" | grep -q '"ok" : 1' || echo "$output" | grep -q "ok: 1"; then
        echo " - ✓ MongoDB is ready!"
        echo "::endgroup::"
        return 0
      else
        echo "::debug::MongoDB not ready yet. Response: $output"
      fi
      ;;

    "nats")
      echo " - Checking NATS connection..."
      if nc -z "$INPUT_HOST" "$INPUT_PORT"; then
        local http_output=$(timeout 5 curl -s "http://$INPUT_HOST:$INPUT_PORT" 2>&1)
        local curl_exit=$?
        echo "::debug::NATS HTTP response: $http_output"
        echo "::debug::curl exit code: $curl_exit"

        # Even if curl fails with a specific HTTP error, the service might be up
        if [ $curl_exit -eq 0 ] || [ $curl_exit -eq 22 ]; then
          echo " - ✓ NATS is ready!"
          echo "::endgroup::"
          return 0
        fi
      else
        echo "::debug::NATS TCP connection failed"
      fi
      ;;

    "kafka")
      echo " - Checking Kafka connection..."
      # Try kcat first, fall back to kafkacat if needed
      local kafka_cmd="kcat"
      if ! command -v kcat >/dev/null 2>&1; then
        kafka_cmd="kafkacat"
      fi

      # Use proper broker addressing format with host and port separate
      local output=$($kafka_cmd -b "$INPUT_HOST" -p "$INPUT_PORT" -L -t non_existent_topic 2>&1)
      local kafka_exit=$?
      echo "::debug::Kafka response: $output"
      echo "::debug::Kafka exit code: $kafka_exit"

      # Check for successful connection - must have exit code 0 OR contain "Metadata for" without error messages
      if { [ $kafka_exit -eq 0 ] && ! echo "$output" | grep -q "ERROR:"; } || { echo "$output" | grep -q "Metadata for" && ! echo "$output" | grep -q "ERROR:"; }; then
        echo " - ✓ Kafka is ready!"
        echo "::endgroup::"
        return 0
      fi
      ;;

    "postgres")
      echo " - Checking PostgreSQL connection..."

      # Build connection string with optional username and database
      local pg_conn="postgresql://"
      if [ -n "$INPUT_USERNAME" ]; then
        pg_conn="${pg_conn}${INPUT_USERNAME}"
        if [ -n "$INPUT_PASSWORD" ]; then
          pg_conn="${pg_conn}:${INPUT_PASSWORD}"
        fi
        pg_conn="${pg_conn}@"
      fi
      pg_conn="${pg_conn}${INPUT_HOST}:${INPUT_PORT}"
      if [ -n "$INPUT_DATABASE" ]; then
        pg_conn="${pg_conn}/${INPUT_DATABASE}"
      fi

      local output=$(PGCONNECT_TIMEOUT=5 psql "$pg_conn" -c "SELECT 1" 2>&1)
      local psql_exit=$?
      echo "::debug::PostgreSQL response: $output"
      echo "::debug::psql exit code: $psql_exit"

      if [ $psql_exit -eq 0 ] && ! echo "$output" | grep -q "error"; then
        echo " - ✓ PostgreSQL is ready!"
        echo "::endgroup::"
        return 0
      else
        echo "::debug::PostgreSQL not ready yet. Response: $output"
      fi
      ;;

    "redis")
      echo " - Checking Redis connection..."
      if [ -z "$INPUT_PASSWORD" ]; then
        local output=$(redis-cli -h "$INPUT_HOST" -p "$INPUT_PORT" ping 2>&1)
        local redis_exit=$?
        echo "::debug::Redis PING response: $output"
        echo "::debug::Redis exit code: $redis_exit"

        # Check if authentication is required but no password was provided
        if echo "$output" | grep -q "NOAUTH Authentication required" && [ -z "$INPUT_PASSWORD" ]; then
          echo "::error::Redis requires authentication, but no password was provided."
          echo "::endgroup::"
          return 1
        fi
      else
        local output=$(redis-cli -h "$INPUT_HOST" -p "$INPUT_PORT" -a "$INPUT_PASSWORD" ping 2>&1)
        local redis_exit=$?
        echo "::debug::Redis PING response: $output"
        echo "::debug::Redis exit code: $redis_exit"
      fi

      if echo "$output" | grep -q "PONG"; then
        echo " - ✓ Redis is ready!"
        echo "::endgroup::"
        return 0
      fi
      ;;

    "android-emulator")
      echo " - Checking Android emulator boot status..."

      # First try to connect to ADB server
      adb connect "$INPUT_HOST:$INPUT_PORT" >/dev/null 2>&1

      # Then check if device is in the list
      if ! adb devices | grep -q "$INPUT_HOST:$INPUT_PORT"; then
        echo "::debug::Device not in ADB devices list, trying to reconnect"
        adb disconnect "$INPUT_HOST:$INPUT_PORT" >/dev/null 2>&1
        adb connect "$INPUT_HOST:$INPUT_PORT" >/dev/null 2>&1
      fi

      local adb_output=$(adb -s "$INPUT_HOST:$INPUT_PORT" shell getprop sys.boot_completed 2>&1)
      local adb_exit=$?
      local boot_status=$(echo "$adb_output" | tr -d '\r')

      echo "::debug::ADB command output: $adb_output"
      echo "::debug::ADB exit code: $adb_exit"
      echo " - Current boot status: $boot_status"

      # Check if simply the ADB connection is successful
      if adb -s "$INPUT_HOST:$INPUT_PORT" shell echo "Connection test" >/dev/null 2>&1; then
        echo " - ADB connection successful"

        # Continue to check for boot completion
        if [ "$boot_status" = "1" ]; then
          echo " - ✓ Android emulator is fully booted and ready!"

          # Provide additional device info
          echo " - Device info:"
          adb -s "$INPUT_HOST:$INPUT_PORT" shell getprop ro.product.model
          adb -s "$INPUT_HOST:$INPUT_PORT" shell getprop ro.build.version.release

          echo "::endgroup::"
          return 0
        fi
      else
        echo "::error::ADB connection failed"
        echo "::endgroup::"
        return 1
      fi
      ;;

    *)
      echo "::warning::Unknown service type: $INPUT_TYPE"
      echo " - Falling back to TCP connection check"
      if check_tcp_port; then
        echo " - ✓ TCP port is open!"
        echo "::endgroup::"
        return 0
      else
        echo "::debug::TCP port is not open yet"
      fi
      ;;
    esac

    # Calculate actual elapsed time
    local current_time=$(date +%s)
    elapsed=$((current_time - start_time))

    # Check timeout
    if [ "$WAIT_INDEFINITELY" = "false" ] && [ $elapsed -ge "$TIMEOUT" ]; then
      echo "::error::Timeout reached. Service $INPUT_TYPE is not ready after $TIMEOUT seconds."
      echo "::endgroup::"
      return 1
    fi

    if [ $((elapsed % 5)) -eq 0 ]; then
      echo " - Still waiting for $INPUT_TYPE service... ($elapsed seconds elapsed)"
    fi
    sleep "$INTERVAL"
  done
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

# Main execution
echo "::group::Service readiness check configuration"
echo " - Service type: $INPUT_TYPE"
echo " - Host: $INPUT_HOST"
echo " - Port: $INPUT_PORT"
if [ "$INPUT_TYPE" = "postgres" ]; then
  if [ -n "$INPUT_USERNAME" ]; then
    echo " - Postgres username: $INPUT_USERNAME"
  fi
  if [ -n "$INPUT_DATABASE" ]; then
    echo " - Postgres database: $INPUT_DATABASE"
  fi
fi
echo " - Timeout: $TIMEOUT seconds"
echo " - Check interval: $INTERVAL seconds"
echo " - Wait indefinitely: $WAIT_INDEFINITELY"
echo "::endgroup::"

validate_inputs
wait_for_service
exit_code=$?
indicate_status $exit_code
exit $exit_code
