Restrict containers
=============================

Restrict containers to local LAN only, no internet.

Install to rootless Docker
------------------------------

```shell
install -m 0755 scripts/restrict-containers-rootless.sh \
    "${HOME}/.local/bin/restrict-containers-rootless.sh"
```

Edit the override.conf:

```shell
systemctl --user edit docker.service

```

Insert this:

```ini
[Service]
ExecStartPost=/home/me/.local/bin/restrict-containers-rootless.sh

```

Replace `/home/me` with your home directory.

Save the file.

Reload the systemd manager configuration:

```shell
systemctl --user daemon-reload

```

Restart Docker (Rootless):

```shell
systemctl --user restart docker.service

```
