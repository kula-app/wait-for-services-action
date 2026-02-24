# Wait for Services GitHub Action

[![GitHub Actions](https://img.shields.io/github/actions/workflow/status/kula-app/wait-for-services-action/build-and-push.yml?branch=main)](https://github.com/kula-app/wait-for-services-action/actions)
[![License](https://img.shields.io/github/license/kula-app/wait-for-services-action)](LICENSE)
[![GitHub Marketplace](https://img.shields.io/badge/marketplace-wait--for--services-blue?logo=github)](https://github.com/marketplace/actions/wait-for-services)

A robust GitHub Action that ensures your services are ready before proceeding with workflow steps. This action performs intelligent service-specific health checks for various services, making it perfect for CI/CD pipelines where service dependencies need to be verified.

## Sub-Actions

In addition to the root Docker-based action, this repository provides **per-service sub-actions** that run as Node.js or composite actions. These are lightweight alternatives that don't require Docker on the runner.

| Sub-Action                              | Type             | Check Method                  |
| --------------------------------------- | ---------------- | ----------------------------- |
| [`mongodb`](mongodb/)                   | Node20           | Native driver ping            |
| [`redis`](redis/)                       | Node20           | Native driver PING/PONG       |
| [`nats`](nats/)                         | Node20           | Native client connect + flush |
| [`kafka`](kafka/)                       | Node20           | Admin client topic listing    |
| [`postgres`](postgres/)                 | Node20           | Native client query           |
| [`tcp`](tcp/)                           | Node20           | TCP port reachability         |
| [`android-emulator`](android-emulator/) | Docker           | ADB boot status               |

## Usage

### Root Action (Docker)

The root action supports all service types via a single `type` input. It requires a Docker-capable runner.

```yaml
- name: Wait for MongoDB
  uses: kula-app/wait-for-services-action@v1
  with:
    type: mongodb
    host: mongodb
    port: 27017
```

### Sub-Actions

Sub-actions run inline in the workflow and don't require Docker on the runner.

#### MongoDB

```yaml
- name: Wait for MongoDB
  uses: kula-app/wait-for-services-action/mongodb@v1
  with:
    host: mongodb
    port: 27017
    timeout: 300
```

#### Redis

```yaml
- name: Wait for Redis
  uses: kula-app/wait-for-services-action/redis@v1
  with:
    host: redis
    port: 6379
    timeout: 300
```

#### NATS

```yaml
- name: Wait for NATS
  uses: kula-app/wait-for-services-action/nats@v1
  with:
    host: nats
    port: 4222
    timeout: 300
```

#### Kafka

```yaml
- name: Wait for Kafka
  uses: kula-app/wait-for-services-action/kafka@v1
  with:
    host: kafka
    port: 9092
    timeout: 300
```

#### PostgreSQL

```yaml
- name: Wait for PostgreSQL
  uses: kula-app/wait-for-services-action/postgres@v1
  with:
    host: postgres
    port: 5432
    username: postgres
    password: postgres
    database: testdb
    timeout: 300
```

#### TCP (Generic)

```yaml
- name: Wait for TCP Service
  uses: kula-app/wait-for-services-action/tcp@v1
  with:
    host: myservice
    port: 8080
    timeout: 60
```

#### Android Emulator

```yaml
- name: Wait for Android Emulator
  uses: kula-app/wait-for-services-action/android-emulator@v1
  with:
    host: android-emulator
    port: 5555
    timeout: 300
```

## Inputs

### Root Action

| Input               | Required | Default | Description                                                                        |
| ------------------- | -------- | ------- | ---------------------------------------------------------------------------------- |
| `type`              | Yes      | -       | Service type (`mongodb`, `nats`, `kafka`, `postgres`, `redis`, `android-emulator`) |
| `host`              | Yes      | -       | Host address of the service                                                        |
| `port`              | Yes      | -       | Port number of the service                                                         |
| `timeout`           | No       | `20`    | Maximum seconds to wait for service readiness                                      |
| `interval`          | No       | `1`     | Seconds between readiness checks                                                   |
| `wait-indefinitely` | No       | `false` | Continue waiting without timeout                                                   |
| `username`          | No       | -       | Username for PostgreSQL                                                            |
| `password`          | No       | -       | Password for PostgreSQL/Redis                                                      |
| `database`          | No       | -       | Database name for PostgreSQL                                                       |

### Sub-Actions

Each sub-action accepts `host`, `port`, `timeout`, `interval`, and `wait-indefinitely`. Service-specific inputs (`username`, `password`, `database`) are only available on the sub-actions that need them (e.g. `postgres`, `redis`).

## Outputs

This action does not produce any outputs. It will:

- Exit with code 0 if the service becomes ready within the timeout
- Exit with code 1 if the service does not become ready within the timeout

## Compatibility

- **Root action**: Works on any GitHub Actions runner that supports Docker (`amd64`/`arm64`)
- **Node sub-actions**: Works on any runner with Node.js 20+
- **TCP sub-action**: Works on any runner with `nc` (netcat)
- **Android emulator sub-action**: Requires Docker

## Development

### Prerequisites

- Node.js 20+
- Yarn 4
- Docker (for root action and android-emulator)
- shfmt (for shell script formatting)

### Setup

```bash
yarn install
```

### Commands

| Command             | Description                                |
| ------------------- | ------------------------------------------ |
| `yarn test`         | Run unit tests (vitest)                    |
| `yarn build`        | Build ncc bundles for all Node sub-actions |
| `yarn lint`         | Run ESLint                                 |
| `yarn format`       | Run Prettier                               |
| `yarn format:check` | Check Prettier formatting                  |
| `yarn all`          | Format, lint, test, and build              |
| `make format`       | Format shell scripts and run Prettier      |

### Project Structure

```
src/
  shared/          # Shared utilities (inputs, wait loop, TCP check, logging)
  mongodb/         # MongoDB check implementation
  redis/           # Redis check implementation
  nats/            # NATS check implementation
  kafka/           # Kafka check implementation
  postgres/        # PostgreSQL check implementation
__tests__/         # Vitest tests
scripts/build.mjs  # ncc build script for all services
<service>/         # Sub-action directories with action.yml + dist/
```

### Adding a New Service

1. Create `src/<service>/check.ts` implementing the check function
2. Create `src/<service>/index.ts` as the entry point
3. Create `<service>/action.yml` with `using: 'node20'`
4. Add the service to `scripts/build.mjs`
5. Add tests in `__tests__/<service>/`
6. Add a test workflow in `.github/workflows/test-<service>.yml`
7. Run `yarn build` and commit the `<service>/dist/` directory

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
