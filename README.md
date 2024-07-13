# AutoSSLx

_A bash CLI tool to ease your nginx and SSL workflows by exposing your web service to the internet with a single command._

### Compatibility

Currently working/testing on

- Amazon Linux 2023

### Usage

**Args**

- `<email>` Your email address for the SSL certificate (required)
- `<domain>` Your domain name for the SSL certificate (required)
- `<service_port>` The port on which your service is running (required)

Just paste the following command directly into your machine's terminal,
and before running, make sure you edit `<email>`, `<domain>` and `<service_port>`.

```
sudo bash -c "$(curl -sSL https://dub.sh/autossl)" - <email> <domain> <service_port>
```
