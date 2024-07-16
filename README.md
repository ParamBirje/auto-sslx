# AutoSSLx

_A bash CLI tool to ease your nginx and SSL workflows by exposing your web service to the internet with a single command._

## Compatibility

Currently working on

- Amazon Linux 2023 (Fedora)

## Usage

**Requirements / Steps**
1. Have your service running locally on a port (using Docker or PM2). Do **not** use port 80 or 443.
2. Configure your DNS (A record) to point to the machine's public IP address.
3. Now run [autosslx](#easy-execution-single-command---default-settings) on the machine.

**Args**

- `<email>` Your email address for the SSL certificate (required)
- `<domain>` Your domain name for the SSL certificate (required)
- `<service_port>` The port on which your service is running (required)

### Easy execution (single command - default settings)

```bash
sudo bash -c "$(curl -sSL https://dub.sh/autosslx)" - <email> <domain> <service_port>
```

Just paste the command above directly into your machine's terminal,
and before running, make sure you edit `<email>`, `<domain>` and `<service_port>`.

### Customized execution

For a customized run, you can execute the following command in your machine which
will get you a `autosslx.sh` script locally which you can edit to your needs.

```bash
curl -sSL https://dub.sh/autosslx -o autosslx.sh
```

**Alternatively**, you can fork this repo and make a script tailored for your usecases!

I have tried to document everything in the script, so it should be relatively easier to make it your own.
