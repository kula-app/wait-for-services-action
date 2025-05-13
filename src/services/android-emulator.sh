#!/bin/bash

check_android_emulator() {
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
  if ! adb -s "$INPUT_HOST:$INPUT_PORT" shell echo "Connection test" >/dev/null 2>&1; then
    echo "::error::ADB connection failed"
    return 1
  fi

  echo " - ADB connection successful"

  # Continue to check for boot completion
  if [ "$boot_status" = "1" ]; then
    echo " - ✓ Android emulator is fully booted and ready!"

    # Provide additional device info
    echo " - Device info:"
    adb -s "$INPUT_HOST:$INPUT_PORT" shell getprop ro.product.model
    adb -s "$INPUT_HOST:$INPUT_PORT" shell getprop ro.build.version.release

    return 0
  fi

  echo "::debug::Android emulator not ready yet."
  return 1
}
