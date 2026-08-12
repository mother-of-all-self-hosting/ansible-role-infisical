<!--
SPDX-FileCopyrightText: 2020 Aaron Raimist
SPDX-FileCopyrightText: 2020 Chris van Dijk
SPDX-FileCopyrightText: 2020 Dominik Zajac
SPDX-FileCopyrightText: 2020 Mickaël Cornière
SPDX-FileCopyrightText: 2020-2024 MDAD project contributors
SPDX-FileCopyrightText: 2020-2024 Slavi Pantaleev
SPDX-FileCopyrightText: 2022 François Darveau
SPDX-FileCopyrightText: 2022 Julian Foad
SPDX-FileCopyrightText: 2022 Warren Bailey
SPDX-FileCopyrightText: 2023 Antonis Christofides
SPDX-FileCopyrightText: 2023 Felix Stupp
SPDX-FileCopyrightText: 2023 Pierre 'McFly' Marty
SPDX-FileCopyrightText: 2024-2026 Suguru Hirahara

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Setting up Infisical

This is an [Ansible](https://www.ansible.com/) role which installs [Infisical](https://github.com/Infisical/infisical) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

Infisical is a platform for secrets, certificates, and privileged access management.

See the project's [documentation](https://infisical.com/docs/self-hosting/overview) to learn what Infisical does and why it might be useful to you.

## Prerequisites

To run an Infisical instance it is necessary to prepare a [Postgres](https://www.postgresql.org/) database server and a [Redis](https://redis.io/) database.

If you are looking for Ansible roles for them, you can check out [ansible-role-postgres](https://github.com/mother-of-all-self-hosting/ansible-role-postgres) and [ansible-role-redis](https://github.com/mother-of-all-self-hosting/ansible-role-redis), both of which are maintained by the [Mother-of-All-Self-Hosting (MASH)](https://github.com/mother-of-all-self-hosting) team. The role for [Valkey](https://valkey.io/) ([ansible-role-valkey](https://github.com/mother-of-all-self-hosting/ansible-role-valkey)) is available as well.

## Adjusting the playbook configuration

To enable Infisical with this role, add the following configuration to your `vars.yml` file.

**Note**: the path should be something like `inventory/host_vars/mash.example.com/vars.yml` if you use the [MASH Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

```yaml
########################################################################
#                                                                      #
# infisical                                                            #
#                                                                      #
########################################################################

infisical_enabled: true

########################################################################
#                                                                      #
# /infisical                                                           #
#                                                                      #
########################################################################
```

### Set the hostname

To enable the Infisical instance you need to set the hostname as well. To do so, add the following configuration to your `vars.yml` file. Make sure to replace `example.com` with your own value.

```yaml
infisical_hostname: "example.com"
```

After adjusting the hostname, make sure to adjust your DNS records to point the domain to your server.

### Set random strings for keys

You also need to set random secure strings for an encryption key and a secret. To do so, add the following configuration to your `vars.yml` file:

```yaml
# Specify a random 16-byte hex string
infisical_environment_variables_encryption_key: ""

# Specify a random 32-byte base64 string
infisical_environment_variables_auth_secret: ""
```

>[!NOTE]
> Other type of values such as one generated with `pwgen -s 64 1` does not work.

### Set variables for the database server

To have the Infisical instance connect to your Postgres server, add the following configuration to your `vars.yml` file.

```yaml
infisical_database_hostname: YOUR_POSTGRES_SERVER_HOSTNAME_HERE
infisical_database_port: 5432
infisical_database_username: YOUR_POSTGRES_SERVER_USERNAME_HERE
infisical_database_password: YOUR_POSTGRES_SERVER_PASSWORD_HERE
infisical_database_name: YOUR_POSTGRES_SERVER_DATABASE_NAME_HERE
```

Make sure to replace the placeholders with your own values.

### Configure a Redis database

It is necessary to set up a Redis database for the Infisical instance. Valkey can also be used instead.

To enable the Redis database for Infisical, add the following configuration to your `vars.yml` file:

```yaml
infisical_redis_hostname: YOUR_REDIS_SERVER_HOSTNAME_HERE
infisical_redis_port: 6379
```

Make sure to replace `YOUR_REDIS_SERVER_HOSTNAME_HERE` with your own value.

### Extending the configuration

There are some additional things you may wish to configure about the service.

Take a look at:

- [`defaults/main.yml`](../defaults/main.yml) for some variables that you can customize via your `vars.yml` file. You can override settings (even those that don't have dedicated playbook variables) using the `infisical_environment_variables_additional_variables` variable

See [this page](https://infisical.com/docs/self-hosting/configuration/envars) on the documentation for a complete list of Infisical's config options that you could put in `infisical_environment_variables_additional_variables`.

## Installing

After configuring the playbook, run the installation command of your playbook as below:

```sh
ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start
```

If you use the MASH playbook, the shortcut commands with the [`just` program](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/just.md) are also available: `just install-all` or `just setup-all`

## Usage

After running the command for installation, Infisical becomes available at the specified hostname like `https://example.com`.

To get started, open the URL with a web browser, and register the account. **Note that the first registered user becomes an administrator automatically.**

## Troubleshooting

### Check the service's logs

You can find the logs in [systemd-journald](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html) by logging in to the server with SSH and running `journalctl -fu infisical` (or how you/your playbook named the service, e.g. `mash-infisical`).

#### Increase logging verbosity

If you want to increase the verbosity, add the following configuration to your `vars.yml` file:

```yaml
infisical_environment_variables_loglevel: debug
```
