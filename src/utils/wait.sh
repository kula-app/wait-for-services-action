#!/bin/bash

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
      if check_mongodb; then
        echo "::endgroup::"
        return 0
      fi
      ;;

    "nats")
      if check_nats; then
        echo "::endgroup::"
        return 0
      fi
      ;;

    "kafka")
      if check_kafka; then
        echo "::endgroup::"
        return 0
      fi
      ;;

    "postgres")
      if check_postgres; then
        echo "::endgroup::"
        return 0
      fi
      ;;

    "redis")
      if check_redis; then
        echo "::endgroup::"
        return 0
      fi
      ;;

    "android-emulator")
      if check_android_emulator; then
        echo "::endgroup::"
        return 0
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
