# Wait for Services GitHub Action

[![GitHub Actions](https://img.shields.io/github/actions/workflow/status/kula-app/wait-for-services-action/build-and-push.yml?branch=main)](https://github.com/kula-app/wait-for-services-action/actions)
[![License](https://img.shields.io/github/license/kula-app/wait-for-services-action)](LICENSE)
[![GitHub Marketplace](https://img.shields.io/badge/marketplace-wait--for--services-blue?logo=github)](https://github.com/marketplace/actions/wait-for-services)

A robust GitHub Action that ensures your services are ready before proceeding with workflow steps. This action performs intelligent service-specific health checks for various services, making it perfect for CI/CD pipelines where service dependencies need to be verified.

## Sub-Actions

In addition to the root Docker-based action, this repository provides **per-service sub-actions** that run as Node.js or composite actions. These are lightweight alternatives that don't require Docker on the runner.

| Sub-Action                              | Type   | Check Method                  |
| --------------------------------------- | ------ | ----------------------------- |
| [`mongodb`](mongodb/)                   | Node20 | Native driver ping            |
| [`redis`](redis/)                       | Node20 | Native driver PING/PONG       |
| [`nats`](nats/)                         | Node20 | Native client connect + flush |
| [`kafka`](kafka/)                       | Node20 | Admin client topic listing    |
| [`postgres`](postgres/)                 | Node20 | Native client query           |
| [`tcp`](tcp/)                           | Node20 | TCP port reachability         |
| [`http`](http/)                         | Node20 | HTTP status code assertion    |
| [`android-emulator`](android-emulator/) | Docker | ADB boot status               |
| [`ios-simulator`](ios-simulator/)       | Shell  | simctl + xcodebuild readiness |

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

#### HTTP

Waits until an HTTP endpoint returns an expected status code. Supports any HTTP method and asserts the raw status code (redirects are not followed, so families like `300-399` can be matched).

```yaml
- name: Wait for HTTP endpoint
  uses: kula-app/wait-for-services-action/http@v1
  with:
    host: myservice
    port: 8080
    path: /health
    method: GET
    expected-status: 200
    timeout: 60
```

**Inputs:**

| Input             | Required | Default | Description                                                                                                     |
| ----------------- | -------- | ------- | --------------------------------------------------------------------------------------------------------------- |
| `scheme`          | No       | `http`  | URL scheme (`http` or `https`)                                                                                  |
| `path`            | No       | `/`     | Request path to check                                                                                           |
| `method`          | No       | `GET`   | HTTP method (`GET`, `POST`, `PUT`, `HEAD`, ...)                                                                 |
| `expected-status` | No       | `200`   | Accepted status codes as a comma-separated list of single codes and/or ranges, e.g. `200`, `200,204`, `300-399` |

The root Docker action exposes the same check via `type: http`:

```yaml
- name: Wait for HTTP endpoint
  uses: kula-app/wait-for-services-action@v1
  with:
    type: http
    host: myservice
    port: 8080
    path: /health
    expected-status: 200,204
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

#### iOS Simulator

Waits for Apple simulator infrastructure to be ready. Requires a macOS runner with Xcode.

```yaml
- name: Wait for iOS Simulator
  uses: kula-app/wait-for-services-action/ios-simulator@v1
  with:
    platform: iOS
    device: iPhone 17 Pro Max
    boot: true
    warm-xcodebuild-settings: true
    project: MyApp.xcodeproj
    scheme: MyAppUITests
    timeout: 300
```

**Inputs:**

| Input                      | Required | Default | Description                                                                    |
| -------------------------- | -------- | ------- | ------------------------------------------------------------------------------ |
| `platform`                 | No       | `iOS`   | Simulator platform (`iOS`, `tvOS`, `visionOS`)                                 |
| `os-version`               | No       | latest  | Runtime version (e.g. `26.4`); auto-selects highest if omitted                 |
| `device`                   | Yes      | -       | Simulator device name (e.g. `iPhone 17 Pro Max`)                               |
| `boot`                     | No       | `true`  | Boot the simulator and wait for bootstatus                                     |
| `warm-xcodebuild-settings` | No       | `false` | Run `xcodebuild -showBuildSettings` after readiness                            |
| `project`                  | No       | -       | Xcode project path (required with warmup)                                      |
| `workspace`                | No       | -       | Xcode workspace path (required with warmup, mutually exclusive with `project`) |
| `scheme`                   | No       | -       | Xcode scheme (required with warmup)                                            |
| `destination`              | No       | -       | Explicit xcodebuild destination; auto-derived from UDID                        |
| `timeout`                  | No       | `300`   | Overall timeout in seconds                                                     |
| `interval`                 | No       | `5`     | Polling interval in seconds                                                    |

**Outputs:**

| Output    | Description              |
| --------- | ------------------------ |
| `udid`    | Resolved simulator UDID  |
| `runtime` | Resolved runtime version |

## Inputs

### Root Action

| Input               | Required | Default | Description                                                                                |
| ------------------- | -------- | ------- | ------------------------------------------------------------------------------------------ |
| `type`              | Yes      | -       | Service type (`mongodb`, `nats`, `kafka`, `postgres`, `redis`, `http`, `android-emulator`) |
| `host`              | Yes      | -       | Host address of the service                                                                |
| `port`              | Yes      | -       | Port number of the service                                                                 |
| `timeout`           | No       | `20`    | Maximum seconds to wait for service readiness                                              |
| `interval`          | No       | `1`     | Seconds between readiness checks                                                           |
| `wait-indefinitely` | No       | `false` | Continue waiting without timeout                                                           |
| `username`          | No       | -       | Username for PostgreSQL                                                                    |
| `password`          | No       | -       | Password for PostgreSQL/Redis                                                              |
| `database`          | No       | -       | Database name for PostgreSQL                                                               |

### Sub-Actions

Each sub-action accepts `host`, `port`, `timeout`, `interval`, and `wait-indefinitely`. Service-specific inputs are only available on the sub-actions that need them — `username`, `password`, `database` (e.g. `postgres`, `redis`) and `scheme`, `path`, `method`, `expected-status` (`http`).

## Outputs

This action does not produce any outputs. It will:

- Exit with code 0 if the service becomes ready within the timeout
- Exit with code 1 if the service does not become ready within the timeout

## Compatibility

- **Root action**: Works on any GitHub Actions runner that supports Docker (`amd64`/`arm64`)
- **Node sub-actions**: Works on any runner with Node.js 20+
- **TCP sub-action**: Works on any runner with `nc` (netcat)
- **Android emulator sub-action**: Requires Docker
- **iOS simulator sub-action**: Requires macOS runner with Xcode and `jq`

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
  tcp/             # TCP port reachability check
  http/            # HTTP status code check
  services/        # Shell check implementations for the root Docker action
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
