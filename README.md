# Wait for Services

This action waits for a service to be ready.

## Supported Services

- MongoDB
- NATS
- Kafka
- Redis
- Android Emulator

## Usage

### Wait for Android Emulator

```yaml
- name: Wait for emulator
  uses: ./ci/actions/wait-for-services
  with:
    type: android-emulator
    host: phone
    port: 5555
```

### Wait for Kafka

```yaml
- name: Wait for Kafka
  uses: ./ci/actions/wait-for-services
  with:
    type: kafka
    host: kafka
    port: 9092
```

### Wait for MongoDB

```yaml
- name: Wait for MongoDB
  uses: ./ci/actions/wait-for-services
  with:
    type: mongodb
    host: mongodb
    port: 27017
```

### Wait for NATS

```yaml
- name: Wait for NATS
  uses: ./ci/actions/wait-for-services
  with:
    type: nats
    host: nats
    port: 4222
```

### Wait for Redis

```yaml
- name: Wait for Redis
  uses: ./ci/actions/wait-for-services
  with:
    type: redis
    host: redis
    port: 6379
```

## Inputs

- `type`: The type of service to wait for. Must be any of `mongodb`, `nats`, `kafka`, `redis`, or `android-emulator`. (Required)
- `host`: The host of the service. (Required)
- `port`: The port of the service. (Required)
- `username`: The username for the service. (Optional)
- `password`: The password for the service. (Optional)
- `timeout`: The timeout for the service to be ready. (Optional, default: 20)
- `interval`: The interval to check if the service is ready. (Optional, default: 1)
- `wait-indefinitely`: If true, the action will wait indefinitely for the service to be ready. Make sure to set a workflow timeout if using this. (Optional, default: false)

## Outputs

No outputs.

This action will fail the job if the service is not ready after the timeout.
