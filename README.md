
# Zabbix Agent Installation Script

This script installs and configures the Zabbix Agent on various Linux distributions supported by Zabbix.

## Usage

To use this script, run the following command:

```sh
curl -fsSL https://wmp.github.io/zabbix/install.sh | sh -s -- <Zabbix Server Address> [Zabbix Agent Version] [Hostname]



Usage: install.sh <Zabbix Server Address> [Zabbix Agent Version] [Hostname]

Arguments:
  <Zabbix Server Address>  The address of the Zabbix server (required).
  [Zabbix Agent Version]   The version of the Zabbix Agent to install. If not provided, the latest version will be used (optional).
  [Hostname]               The hostname to be configured for the Zabbix Agent. If not provided, the system hostname will be used (optional).

Example:
  curl -fsSL https://wmp.github.io/zabbix/install.sh | sh -s -- zabbix.example.com 7.0 my-hostname
```

This command installs the Zabbix Agent version 7.0, configures it to connect to `zabbix.example.com`, and sets the hostname to `my-hostname`.

## Script Details

The script performs the following steps:

1. Checks if the script is running as root.
2. Detects the operating system and version.
3. Downloads and installs the appropriate Zabbix repository package.
4. Installs the Zabbix Agent.
5. Configures the Zabbix Agent with the provided server address and hostname.
6. Restarts the Zabbix Agent service.

### Supported Systems

- **Debian-based systems**: Downloads the appropriate `.deb` package and installs it using `dpkg`.
- **Red Hat-based systems**: Downloads the appropriate `.rpm` package and installs it using `rpm`.
- **SUSE-based systems**: Downloads the appropriate `.rpm` package and installs it using `rpm` and `zypper`.

### Configuration

The Zabbix Agent configuration file is located at `/etc/zabbix/zabbix_agent2.d/zabbix_agent2.conf`. The script sets the `Hostname`, `HostnameItem`, `Server`, and `ServerActive` parameters based on the provided arguments.

## License

This script is provided under the [MIT License](LICENSE).
