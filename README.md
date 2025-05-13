# Wait for Services GitHub Action

A GitHub Action to wait for various services to be ready before proceeding with workflow steps.

## Code Structure

The codebase has been refactored into a modular structure:

```
.
├── entrypoint.sh             # Main entry point script
└── src/
    ├── services/             # Service-specific implementations
    │   ├── android-emulator.sh  # Android emulator service checks
    │   ├── kafka.sh          # Kafka service checks
    │   ├── mongodb.sh        # MongoDB service checks
    │   ├── nats.sh           # NATS service checks
    │   ├── postgres.sh       # PostgreSQL service checks
    │   └── redis.sh          # Redis service checks
    └── utils/                # Shared utility functions
        ├── common.sh         # Common utility functions
        └── wait.sh           # Main waiting logic
```

## Supported Services

- MongoDB
- NATS
- Kafka
- PostgreSQL
- Redis
- Android Emulator
- Generic TCP service (fallback)

## How to Add a New Service

1. Create a new service file in `src/services/` directory
2. Implement a `check_servicename()` function that returns 0 when service is ready
3. Update the `wait_for_service()` function in `src/utils/wait.sh` to include your service
4. Update the entrypoint.sh to source your new service file

## Inputs

- `type`: Service type (mongodb, nats, kafka, postgres, redis, android-emulator)
- `host`: Host address of the service
- `port`: Port number of the service
- `timeout`: Maximum seconds to wait (default: 20)
- `interval`: Seconds between checks (default: 1)
- `wait_indefinitely`: Continue waiting without timeout (default: false)

Additional service-specific inputs:
- For PostgreSQL: `username`, `password`, `database`
- For Redis: `password`

See [action.yml](action.yml) for more details.

## Usage

### Wait for Android Emulator

```yaml
- name: Wait for emulator
  uses: kula-app/wait-for-services@main
  with:
    type: android-emulator
    host: phone
    port: 5555
```

### Wait for Kafka

```yaml
- name: Wait for Kafka
  uses: kula-app/wait-for-services@main
  with:
    type: kafka
    host: kafka
    port: 9092
```

### Wait for MongoDB

```yaml
- name: Wait for MongoDB
  uses: kula-app/wait-for-services@main
  with:
    type: mongodb
    host: mongodb
    port: 27017
```

### Wait for NATS

```yaml
- name: Wait for NATS
  uses: kula-app/wait-for-services@main
  with:
    type: nats
    host: nats
    port: 4222
```

### Wait for PostgreSQL

```yaml
- name: Wait for PostgreSQL
  uses: kula-app/wait-for-services@main
  with:
    type: postgres
    host: localhost
    port: 5432
    username: postgres
    password: postgres
    database: testdb
```

### Wait for Redis

```yaml
- name: Wait for Redis
  uses: kula-app/wait-for-services@main
  with:
    type: redis
    host: redis
    port: 6379
```

## Outputs

No outputs.

This action will fail the job if the service is not ready after the timeout.
