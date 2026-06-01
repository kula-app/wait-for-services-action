#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Logging helpers — GitHub Actions aware
# ---------------------------------------------------------------------------

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  IS_GHA=true
else
  IS_GHA=false
fi

log_info() { echo "$*"; }
log_error() {
  if $IS_GHA; then echo "::error::$*"; else echo "ERROR: $*" >&2; fi
}
log_warning() {
  if $IS_GHA; then echo "::warning::$*"; else echo "WARNING: $*" >&2; fi
}
begin_group() {
  if $IS_GHA; then echo "::group::$*"; else echo "== $* =="; fi
}
end_group() {
  if $IS_GHA; then echo "::endgroup::"; fi
}
set_output() {
  if $IS_GHA && [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "$1=$2" >>"$GITHUB_OUTPUT"
  fi
  log_info "Output $1=$2"
}

# ---------------------------------------------------------------------------
# Input parsing — environment variables (GitHub Actions) or CLI flags
# ---------------------------------------------------------------------------

PLATFORM="${INPUT_PLATFORM:-iOS}"
OS_VERSION="${INPUT_OS_VERSION:-}"
DEVICE="${INPUT_DEVICE:-}"
BOOT="${INPUT_BOOT:-true}"
WARM_XCODEBUILD_SETTINGS="${INPUT_WARM_XCODEBUILD_SETTINGS:-false}"
PROJECT="${INPUT_PROJECT:-}"
WORKSPACE="${INPUT_WORKSPACE:-}"
SCHEME="${INPUT_SCHEME:-}"
DESTINATION="${INPUT_DESTINATION:-}"
TIMEOUT="${INPUT_TIMEOUT:-300}"
INTERVAL="${INPUT_INTERVAL:-5}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform) PLATFORM="$2"; shift 2 ;;
    --os-version) OS_VERSION="$2"; shift 2 ;;
    --device) DEVICE="$2"; shift 2 ;;
    --boot) BOOT="$2"; shift 2 ;;
    --warm-xcodebuild-settings) WARM_XCODEBUILD_SETTINGS="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --scheme) SCHEME="$2"; shift 2 ;;
    --destination) DESTINATION="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --interval) INTERVAL="$2"; shift 2 ;;
    *) log_error "Unknown argument: $1"; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

if [ -z "$DEVICE" ]; then
  log_error "Input 'device' is required"
  exit 1
fi

if [ "$WARM_XCODEBUILD_SETTINGS" = "true" ]; then
  if [ -z "$SCHEME" ]; then
    log_error "Input 'scheme' is required when warm-xcodebuild-settings is enabled"
    exit 1
  fi
  if [ -z "$PROJECT" ] && [ -z "$WORKSPACE" ]; then
    log_error "Either 'project' or 'workspace' is required when warm-xcodebuild-settings is enabled"
    exit 1
  fi
  if [ -n "$PROJECT" ] && [ -n "$WORKSPACE" ]; then
    log_error "Only one of 'project' or 'workspace' should be specified, not both"
    exit 1
  fi
fi

if ! command -v xcrun &>/dev/null; then
  log_error "xcrun is not available — this action requires macOS with Xcode"
  exit 1
fi

if ! command -v jq &>/dev/null; then
  log_error "jq is not available — install it with: brew install jq"
  exit 1
fi

log_info "Configuration:"
log_info "  Platform: $PLATFORM"
log_info "  OS Version: ${OS_VERSION:-<auto>}"
log_info "  Device: $DEVICE"
log_info "  Boot: $BOOT"
log_info "  Warm xcodebuild: $WARM_XCODEBUILD_SETTINGS"
log_info "  Timeout: ${TIMEOUT}s"
log_info "  Interval: ${INTERVAL}s"

# ---------------------------------------------------------------------------
# Timeout helper — runs a command with a wall-clock timeout (no GNU coreutils)
# ---------------------------------------------------------------------------

run_with_timeout() {
  local timeout=$1
  shift

  "$@" &
  local pid=$!

  local count=0
  while kill -0 "$pid" 2>/dev/null; do
    if [ "$count" -ge "$timeout" ]; then
      kill -TERM "$pid" 2>/dev/null || true
      sleep 1
      kill -KILL "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      return 124
    fi
    sleep 1
    count=$((count + 1))
  done

  wait "$pid"
}

# ---------------------------------------------------------------------------
# Runtime resolution
# ---------------------------------------------------------------------------

resolve_runtime() {
  local runtimes_json
  runtimes_json=$(xcrun simctl list runtimes -j 2>/dev/null)

  if [ -n "$OS_VERSION" ]; then
    local runtime
    runtime=$(echo "$runtimes_json" | jq -r --arg p "$PLATFORM" --arg v "$OS_VERSION" '
      [.runtimes[]
        | select(.isAvailable == true)
        | select(
            .platform == $p
            or ($p == "visionOS" and .platform == "xrOS")
            or ($p == "xrOS" and .platform == "visionOS")
          )
        | select(.version == $v or (.version | startswith($v + ".")))
      ] | sort_by(.version) | last // empty
    ')

    if [ -z "$runtime" ] || [ "$runtime" = "null" ]; then
      return 1
    fi

    RESOLVED_RUNTIME_VERSION=$(echo "$runtime" | jq -r '.version')
    RESOLVED_RUNTIME_ID=$(echo "$runtime" | jq -r '.identifier')
  else
    local runtime
    runtime=$(echo "$runtimes_json" | jq -r --arg p "$PLATFORM" '
      [.runtimes[]
        | select(.isAvailable == true)
        | select(
            .platform == $p
            or ($p == "visionOS" and .platform == "xrOS")
            or ($p == "xrOS" and .platform == "visionOS")
          )
      ] | sort_by(.version) | last // empty
    ')

    if [ -z "$runtime" ] || [ "$runtime" = "null" ]; then
      return 1
    fi

    RESOLVED_RUNTIME_VERSION=$(echo "$runtime" | jq -r '.version')
    RESOLVED_RUNTIME_ID=$(echo "$runtime" | jq -r '.identifier')
  fi

  return 0
}

list_available_runtimes() {
  xcrun simctl list runtimes -j 2>/dev/null | jq -r '
    .runtimes[]
    | select(.isAvailable == true)
    | "  \(.platform) \(.version) (\(.identifier))"
  '
}

# ---------------------------------------------------------------------------
# Device resolution
# ---------------------------------------------------------------------------

resolve_device() {
  local devices_json
  devices_json=$(xcrun simctl list devices available -j 2>/dev/null)

  RESOLVED_UDID=$(echo "$devices_json" | jq -r --arg rid "$RESOLVED_RUNTIME_ID" --arg name "$DEVICE" '
    .devices[$rid] // []
    | map(select(.name == $name))
    | first
    | .udid // empty
  ')

  if [ -z "$RESOLVED_UDID" ]; then
    return 1
  fi

  return 0
}

list_available_devices() {
  xcrun simctl list devices available -j 2>/dev/null | jq -r --arg rid "$RESOLVED_RUNTIME_ID" '
    .devices[$rid] // []
    | .[]
    | "  \(.name) (\(.udid)) — \(.state)"
  '
}

# ---------------------------------------------------------------------------
# Runtime reload fallback
# ---------------------------------------------------------------------------

attempt_runtime_reload() {
  begin_group "Attempting runtime reload"

  log_info "Unmounting simulator volumes..."
  for dir in /Library/Developer/CoreSimulator/Volumes/*; do
    [ -e "$dir" ] || continue
    log_info "  Ejecting $dir"
    sudo diskutil unmount force "$dir" 2>/dev/null || true
  done

  log_info "Restarting CoreSimulator services..."
  sudo launchctl kill -9 system/com.apple.CoreSimulator.simdiskimaged 2>/dev/null || true
  sudo pkill -9 com.apple.CoreSimulator.CoreSimulatorService 2>/dev/null || true

  log_info "Waiting for runtime to become available..."
  local count=0
  local max_attempts=$(( TIMEOUT / INTERVAL ))
  [ "$max_attempts" -lt 1 ] && max_attempts=1

  while [ "$count" -lt "$max_attempts" ]; do
    if resolve_runtime; then
      log_info "Runtime became available after $count attempts"
      end_group
      return 0
    fi
    count=$((count + 1))
    sleep "$INTERVAL"
  done

  end_group
  return 1
}

# ---------------------------------------------------------------------------
# Boot simulator
# ---------------------------------------------------------------------------

boot_simulator() {
  begin_group "Booting simulator $DEVICE ($RESOLVED_UDID)"

  xcrun simctl boot "$RESOLVED_UDID" 2>/dev/null || {
    local state
    state=$(xcrun simctl list devices -j 2>/dev/null | jq -r --arg udid "$RESOLVED_UDID" '
      [.devices[][] | select(.udid == $udid)] | first | .state // "Unknown"
    ')
    if [ "$state" = "Booted" ]; then
      log_info "Simulator is already booted"
      end_group
      return 0
    fi
    log_error "Failed to boot simulator (current state: $state)"
    end_group
    return 1
  }

  log_info "Waiting for boot status..."
  local boot_timeout=$((TIMEOUT > 180 ? 180 : TIMEOUT))
  if run_with_timeout "$boot_timeout" xcrun simctl bootstatus "$RESOLVED_UDID"; then
    log_info "Simulator boot completed"
  else
    local exit_code=$?
    if [ "$exit_code" -eq 124 ]; then
      log_warning "bootstatus timed out after ${boot_timeout}s — simulator may still be booting"
    else
      log_warning "bootstatus exited with code $exit_code"
    fi
  fi

  end_group
}

# ---------------------------------------------------------------------------
# Warm xcodebuild -showBuildSettings
# ---------------------------------------------------------------------------

warm_xcodebuild_settings() {
  begin_group "Warming xcodebuild -showBuildSettings"

  local dest="$DESTINATION"
  if [ -z "$dest" ]; then
    dest="platform=${PLATFORM} Simulator,id=${RESOLVED_UDID}"
  fi

  local -a cmd=(xcodebuild -showBuildSettings)
  if [ -n "$PROJECT" ]; then
    cmd+=(-project "$PROJECT")
  fi
  if [ -n "$WORKSPACE" ]; then
    cmd+=(-workspace "$WORKSPACE")
  fi
  cmd+=(-scheme "$SCHEME" -destination "$dest")

  log_info "Running: ${cmd[*]}"

  local count=0
  local max_attempts=$(( TIMEOUT / INTERVAL ))
  [ "$max_attempts" -lt 1 ] && max_attempts=1

  while [ "$count" -lt "$max_attempts" ]; do
    if run_with_timeout 60 "${cmd[@]}" >/dev/null 2>&1; then
      log_info "xcodebuild -showBuildSettings completed after $((count + 1)) attempt(s)"
      end_group
      return 0
    fi
    count=$((count + 1))
    log_info "Attempt $count failed, retrying in ${INTERVAL}s..."
    sleep "$INTERVAL"
  done

  log_warning "xcodebuild -showBuildSettings did not succeed within timeout"
  end_group
  return 1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

RESOLVED_RUNTIME_VERSION=""
RESOLVED_RUNTIME_ID=""
RESOLVED_UDID=""

begin_group "Resolving simulator runtime"

if ! resolve_runtime; then
  log_warning "Runtime not immediately available for ${PLATFORM} ${OS_VERSION:-<latest>}"

  if ! attempt_runtime_reload; then
    log_error "Runtime not available for ${PLATFORM} ${OS_VERSION:-<latest>}"
    log_error "Available runtimes:"
    list_available_runtimes | while IFS= read -r line; do log_error "$line"; done
    exit 1
  fi
fi

log_info "Resolved runtime: ${RESOLVED_RUNTIME_VERSION} (${RESOLVED_RUNTIME_ID})"
end_group

begin_group "Resolving simulator device"

if ! resolve_device; then
  log_error "Device '${DEVICE}' not found for runtime ${RESOLVED_RUNTIME_ID}"
  log_error "Available devices for this runtime:"
  list_available_devices | while IFS= read -r line; do log_error "$line"; done
  exit 1
fi

log_info "Resolved device: ${DEVICE} (${RESOLVED_UDID})"
end_group

if [ "$BOOT" = "true" ]; then
  boot_simulator
fi

if [ "$WARM_XCODEBUILD_SETTINGS" = "true" ]; then
  warm_xcodebuild_settings
fi

set_output "udid" "$RESOLVED_UDID"
set_output "runtime" "$RESOLVED_RUNTIME_VERSION"

log_info "iOS Simulator is ready: ${DEVICE} (${RESOLVED_UDID}) on ${PLATFORM} ${RESOLVED_RUNTIME_VERSION}"
