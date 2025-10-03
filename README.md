# Wait for Services GitHub Action

[![GitHub Actions](https://img.shields.io/github/actions/workflow/status/kula-app/wait-for-services-action/build-and-push.yml?branch=main)](https://github.com/kula-app/wait-for-services-action/actions)
[![License](https://img.shields.io/github/license/kula-app/wait-for-services-action)](LICENSE)
[![GitHub Marketplace](https://img.shields.io/badge/marketplace-wait--for--services-blue?logo=github)](https://github.com/marketplace/actions/wait-for-services)

A robust GitHub Action that ensures your services are ready before proceeding with workflow steps. This action performs intelligent service-specific health checks for various services, making it perfect for CI/CD pipelines where service dependencies need to be verified.

## Features

- 🚀 **Multiple Service Support**:
  - MongoDB
  - NATS
  - Kafka
  - PostgreSQL
  - Redis
  - Android Emulator
  - Generic TCP service (fallback)
- ⏱️ **Configurable Timeouts**: Set custom wait times and check intervals
- 🔄 **Indefinite Waiting**: Option to wait indefinitely for services
- 🔍 **Service-Specific Checks**: Intelligent health checks for each service type
- 📊 **Detailed Logging**: Comprehensive status reporting and debugging information
- 🐳 **Docker-based**: Runs in a container with all necessary tools pre-installed

## Usage

### Basic Example

```yaml
- name: Wait for PostgreSQL
  uses: kula-app/wait-for-services-action@v1
  with:
    type: postgres
    host: localhost
    port: 5432
    username: postgres
    password: postgres
    database: testdb
```

### Service-Specific Examples

#### MongoDB
```yaml
- name: Wait for MongoDB
  uses: kula-app/wait-for-services-action@v1
  with:
    type: mongodb
    host: mongodb
    port: 27017
```

#### NATS
```yaml
- name: Wait for NATS
  uses: kula-app/wait-for-services-action@v1
  with:
    type: nats
    host: nats
    port: 4222
```

#### Kafka
```yaml
- name: Wait for Kafka
  uses: kula-app/wait-for-services-action@v1
  with:
    type: kafka
    host: kafka
    port: 9092
```

#### Redis
```yaml
- name: Wait for Redis
  uses: kula-app/wait-for-services-action@v1
  with:
    type: redis
    host: redis
    port: 6379
```

#### Android Emulator
```yaml
- name: Wait for Android Emulator
  uses: kula-app/wait-for-services-action@v1
  with:
    type: android-emulator
    host: phone
    port: 5555
```

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `type` | Yes | - | Service type (`mongodb`, `nats`, `kafka`, `postgres`, `redis`, `android-emulator`) |
| `host` | Yes | - | Host address of the service |
| `port` | Yes | - | Port number of the service |
| `timeout` | No | `20` | Maximum seconds to wait for service readiness |
| `interval` | No | `1` | Seconds between readiness checks |
| `wait-indefinitely` | No | `false` | Continue waiting without timeout |
| `username` | No* | - | Username for PostgreSQL |
| `password` | No* | - | Password for PostgreSQL/Redis |
| `database` | No* | - | Database name for PostgreSQL |

*Required for specific services (PostgreSQL/Redis)

## Outputs

This action does not produce any outputs. It will:
- Exit with code 0 if the service becomes ready within the timeout
- Exit with code 1 if the service does not become ready within the timeout
- Fail the workflow step if the service is not ready

## Compatibility

- **Runner**: Works on any GitHub Actions runner that supports Docker
- **Architecture**: Supports both `amd64` and `arm64` architectures
- **Services**: Compatible with the following service versions:
  - MongoDB: 8.0.9+
  - NATS: 2.11.3+
  - Kafka: 3.7.0+
  - PostgreSQL: 15+
  - Redis: 7.4.3+
  - Android Emulator: 30.1.2+

## Development

### Prerequisites

- Docker
- shfmt (for shell script formatting)
- Yarn 4.9.1+

### Local Development

1. Clone the repository
2. Install dependencies:
   ```bash
   yarn install
   ```
3. Format code:
   ```bash
   make format
   ```

### Adding a New Service

1. Create a new service file in `src/services/` directory
2. Implement a `check_servicename()` function that returns 0 when service is ready
3. Update the `wait_for_service()` function in `src/utils/wait.sh`
4. Update `entrypoint.sh` to source your new service file
5. Add appropriate tests in `.github/workflows/`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
