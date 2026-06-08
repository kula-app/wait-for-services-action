#!/bin/bash

# Return 0 if $1 matches the comma-separated expected-status spec in $2.
# Each token is either a single code (e.g. 200) or an inclusive range (e.g. 300-399).
http_status_matches() {
  local status="$1"
  local spec="$2"

  local IFS=','
  local token
  for token in $spec; do
    token="${token//[[:space:]]/}"
    [ -z "$token" ] && continue

    if [[ "$token" =~ ^[0-9]+$ ]]; then
      if [ "$status" -eq "$token" ]; then
        return 0
      fi
    elif [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      local min="${BASH_REMATCH[1]}"
      local max="${BASH_REMATCH[2]}"
      if [ "$status" -ge "$min" ] && [ "$status" -le "$max" ]; then
        return 0
      fi
    else
      echo "::error::Invalid expected-status token: $token. Use single codes (e.g. 200) or ranges (e.g. 300-399)."
      return 2
    fi
  done

  return 1
}

check_http() {
  local scheme="${INPUT_SCHEME:-http}"
  local path="${INPUT_PATH:-/}"
  local method="${INPUT_METHOD:-GET}"
  local expected="${INPUT_EXPECTED_STATUS:-200}"
  local url="$scheme://$INPUT_HOST:$INPUT_PORT$path"

  echo " - Checking HTTP endpoint $method $url..."

  local status
  # Do not follow redirects (no -L) so the raw status code is asserted.
  status=$(curl -s -o /dev/null -w '%{http_code}' -X "$method" --max-time 5 "$url" 2>/dev/null)
  echo "::debug::HTTP $method $url returned status: $status"

  if [ -z "$status" ] || [ "$status" = "000" ]; then
    echo "::debug::HTTP request failed or endpoint not reachable yet"
    return 1
  fi

  if http_status_matches "$status" "$expected"; then
    echo " - ✓ HTTP endpoint returned $status (expected $expected)"
    return 0
  fi

  echo "::debug::HTTP endpoint returned $status, expected $expected"
  return 1
}
