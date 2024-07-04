# Zabbix Web Unit

This repo contains files necesary to build a container image for the Zabbix Frontend using the NGINX Unit Application runtime.
This is intended as drop in replacement for the zabbix/zabbix-web-[apache,nginx]-mysql images.

## The Differences

- Built on the Wolfi (un)distro, smaller footprint but keeping GLIBC.
- Uses NGINX Unit, replacing Nginx, Apache, PHP-FPM, and supervisord.
- Changed docker-entrypoint script to be Dash/Ash compatible, removing Bash requirement.
- Test DB connection using PHP script, removing mysql-admin requirement.
- Added a preloading script for opcache, thus improving both throughput and latencies, (at least in my tests).

## Container images

Container images have been published to docker hub and can be found [here][dh-repo]

Following image tags currently exist:

| Zabbix Version | Image repo                          | Tags                                             |
|----------------|-------------------------------------|--------------------------------------------------|
| 6.0.31         | [comprime/zabbix-web-unit][dh-tags] | [6.0-latest][dh-6.0-latest], [6.0.31][dh-6.0.31] |
| 6.4.16         | [comprime/zabbix-web-unit][dh-tags] | [6.4-latest][dh-6.4-latest], [6.4.16][dh-6.4.16] |
| 7.0.0          | [comprime/zabbix-web-unit][dh-tags] | [7.0-latest][dh-7.0-latest], [7.0.0][dh-7.0.0]   |

[dh-repo]: https://hub.docker.com/r/comprime/zabbix-web-unit
[dh-tags]: https://hub.docker.com/r/comprime/zabbix-web-unit/tags
[dh-6.0-latest]: https://hub.docker.com/layers/comprime/zabbix-web-unit/6.0-latest/images/sha256-cd7b54542c989ae4c871146974e54beb8a47c86a8c1cd85378849710bbfb4d24
[dh-6.0.31]:     https://hub.docker.com/layers/comprime/zabbix-web-unit/6.0.31/images/sha256-cd7b54542c989ae4c871146974e54beb8a47c86a8c1cd85378849710bbfb4d24
[dh-6.4-latest]: https://hub.docker.com/layers/comprime/zabbix-web-unit/6.4-latest/images/sha256-f506a38866219386853e7e81f9db13f090b31f671c8a5d38e729ed4470c7c5d7
[dh-6.4.16]:     https://hub.docker.com/layers/comprime/zabbix-web-unit/6.4.16/images/sha256-f506a38866219386853e7e81f9db13f090b31f671c8a5d38e729ed4470c7c5d7
[dh-7.0-latest]: https://hub.docker.com/layers/comprime/zabbix-web-unit/7.0-latest/images/sha256-82441934b2f9883238ec2cba995824222a151cc8556552479d926d1bcd50b64f
[dh-7.0.0]:      https://hub.docker.com/layers/comprime/zabbix-web-unit/7.0.0/images/sha256-82441934b2f9883238ec2cba995824222a151cc8556552479d926d1bcd50b64f


## Build instructions

Image is built using [melange](https://github.com/chainguard-dev/melange), [apko](https://github.com/chainguard-dev/apko), [skopeo](https://github.com/containers/skopeo), and [make](https://www.gnu.org/software/make/).
Melange then has a dependency on [bubblewrap](https://github.com/containers/bubblewrap).

If you have either docker or podman installed, just running `make docker-make` will take care of everything for you and build the images.
