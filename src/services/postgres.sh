#!/bin/bash

check_postgres() {
  echo " - Checking PostgreSQL connection..."

  echo "::debug::Checking PostgreSQL TCP connection to $INPUT_HOST:$INPUT_PORT"
  if ! nc -z "$INPUT_HOST" "$INPUT_PORT"; then
    echo "::debug::PostgreSQL TCP connection failed"
    return 1
  fi

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

  echo "::debug::Checking PostgreSQL connection using $pg_conn"
  local output=$(PGCONNECT_TIMEOUT=5 psql "$pg_conn" -c "SELECT 1" 2>&1)
  local psql_exit=$?
  echo "::debug::PostgreSQL response: $output"
  echo "::debug::psql exit code: $psql_exit"

  if [ $psql_exit -eq 0 ] && ! echo "$output" | grep -q "error"; then
    echo " - ✓ PostgreSQL is ready!"
    return 0
  fi

  echo "::debug::PostgreSQL not ready yet."
  return 1
}
