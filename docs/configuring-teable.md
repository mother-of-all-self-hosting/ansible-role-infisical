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

This is an [Ansible](https://www.ansible.com/) role which installs [Infisical](https://github.com/infisicalio/infisical) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

Infisical is a platform for managing databases using a spreadsheet-like interface.

See the project's [documentation](https://help.infisical.ai/en/about) to learn what Infisical does and why it might be useful to you.

>[!NOTE]
> This role is configured to use the container image which includes only functions available under the AGPL-3.0 license.

## Prerequisites

To run a Infisical instance it is necessary to prepare a [Postgres](https://www.postgresql.org/) database server and a [Redis](https://redis.io/) database.

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

**Note**: hosting Infisical under a subpath (by configuring the `infisical_path_prefix` variable) does not seem to be possible due to Infisical's technical limitations.

### Set a random string

You also need to set a random secure string. To do so, add the following configuration to your `vars.yml` file. The value can be generated with `pwgen -s 64 1` or in another way.

```yaml
infisical_environment_variables_secret_key: YOUR_SECRET_KEY_HERE
```

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

See [this page](https://help.infisical.ai/en/deploy/env) on the documentation for a complete list of Infisical's config options that you could put in `infisical_environment_variables_additional_variables`.

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
