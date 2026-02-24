#!/bin/bash
set -e

HOST="${INPUT_HOST:?Missing INPUT_HOST}"
PORT="${INPUT_PORT:?Missing INPUT_PORT}"
TIMEOUT="${INPUT_TIMEOUT:-20}"
INTERVAL="${INPUT_INTERVAL:-1}"
WAIT_INDEFINITELY="${INPUT_WAIT_INDEFINITELY:-false}"

check_android_emulator() {
  # Try to connect to ADB server
  adb connect "$HOST:$PORT" >/dev/null 2>&1

  # Reconnect if device not in list
  if ! adb devices | grep -q "$HOST:$PORT"; then
    adb disconnect "$HOST:$PORT" >/dev/null 2>&1
    adb connect "$HOST:$PORT" >/dev/null 2>&1
  fi

  # Check ADB connection
  if ! adb -s "$HOST:$PORT" shell echo "Connection test" >/dev/null 2>&1; then
    return 1
  fi

  # Check boot completion
  local boot_status
  boot_status=$(adb -s "$HOST:$PORT" shell getprop sys.boot_completed 2>&1 | tr -d '\r')
  if [ "$boot_status" = "1" ]; then
    return 0
  fi

  return 1
}

echo "::group::Waiting for Android emulator at ${HOST}:${PORT}"
echo " Timeout: ${TIMEOUT}s | Interval: ${INTERVAL}s | Wait indefinitely: ${WAIT_INDEFINITELY}"

START=$(date +%s)
while true; do
  if check_android_emulator; then
    echo "::endgroup::"
    echo "::group::Service status check summary"
    echo " Service: android-emulator"
    echo " Host: ${HOST}"
    echo " Port: ${PORT}"
    echo " Status: READY"
    echo " Device info:"
    adb -s "$HOST:$PORT" shell getprop ro.product.model
    adb -s "$HOST:$PORT" shell getprop ro.build.version.release
    echo "::endgroup::"
    exit 0
  fi

  ELAPSED=$(( $(date +%s) - START ))
  if [ "$WAIT_INDEFINITELY" != "true" ] && [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "::endgroup::"
    echo "::error::Android emulator at ${HOST}:${PORT} did not become ready within ${TIMEOUT} seconds"
    exit 1
  fi

  if [ $(( ELAPSED % 5 )) -eq 0 ] && [ "$ELAPSED" -gt 0 ]; then
    echo " Still waiting... (${ELAPSED}s elapsed)"
  fi
  sleep "$INTERVAL"
done
