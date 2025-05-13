#!/bin/bash
set -e

# Set defaults
TIMEOUT=${INPUT_TIMEOUT:-20}
INTERVAL=${INPUT_INTERVAL:-1}
WAIT_INDEFINITELY=${INPUT_WAIT_INDEFINITELY:-false}

# Source utility functions
source "$(dirname "$0")/src/utils/common.sh"
source "$(dirname "$0")/src/utils/wait.sh"

# Source service-specific modules
if [ -n "$INPUT_TYPE" ]; then
  case "$INPUT_TYPE" in
  "mongodb")
    source "$(dirname "$0")/src/services/mongodb.sh"
    ;;
  "nats")
    source "$(dirname "$0")/src/services/nats.sh"
    ;;
  "kafka")
    source "$(dirname "$0")/src/services/kafka.sh"
    ;;
  "postgres")
    source "$(dirname "$0")/src/services/postgres.sh"
    ;;
  "redis")
    source "$(dirname "$0")/src/services/redis.sh"
    ;;
  "android-emulator")
    source "$(dirname "$0")/src/services/android-emulator.sh"
    ;;
  *)
    echo "::warning::Unknown service type: $INPUT_TYPE. Will use basic TCP check."
    ;;
  esac
fi

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
