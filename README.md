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
| 6.0.32         | [comprime/zabbix-web-unit][dh-tags] | [6.0-latest][dh-6.0-latest], [6.0.32][dh-6.0.32] |
| 6.4.17         | [comprime/zabbix-web-unit][dh-tags] | [6.4-latest][dh-6.4-latest], [6.4.17][dh-6.4.17] |
| 7.0.0          | [comprime/zabbix-web-unit][dh-tags] | [7.0-latest][dh-7.0-latest], [7.0.0][dh-7.0.0]   |

[dh-repo]: https://hub.docker.com/r/comprime/zabbix-web-unit
[dh-tags]: https://hub.docker.com/r/comprime/zabbix-web-unit/tags
[dh-6.0-latest]: https://hub.docker.com/layers/comprime/zabbix-web-unit/6.0-latest/images/sha256-eff8dd34c0947cc161212d07990866ff262732462ec80e3e8cd4dfd33bba8b63
[dh-6.0.32]:     https://hub.docker.com/layers/comprime/zabbix-web-unit/6.0.32/images/sha256-eff8dd34c0947cc161212d07990866ff262732462ec80e3e8cd4dfd33bba8b63
[dh-6.4-latest]: https://hub.docker.com/layers/comprime/zabbix-web-unit/6.4-latest/images/sha256-08c1f05696bc21bb9ce051c24006302269a5e215f017a7a685dbeeab8b400ed8
[dh-6.4.17]:     https://hub.docker.com/layers/comprime/zabbix-web-unit/6.4.17/images/sha256-08c1f05696bc21bb9ce051c24006302269a5e215f017a7a685dbeeab8b400ed8
[dh-7.0-latest]: https://hub.docker.com/layers/comprime/zabbix-web-unit/7.0-latest/images/sha256-82441934b2f9883238ec2cba995824222a151cc8556552479d926d1bcd50b64f
[dh-7.0.0]:      https://hub.docker.com/layers/comprime/zabbix-web-unit/7.0.0/images/sha256-82441934b2f9883238ec2cba995824222a151cc8556552479d926d1bcd50b64f

## Build instructions

Image is built using [melange](https://github.com/chainguard-dev/melange), [apko](https://github.com/chainguard-dev/apko), [skopeo](https://github.com/containers/skopeo), and [make](https://www.gnu.org/software/make/).
Melange then has a dependency on [bubblewrap](https://github.com/containers/bubblewrap).

If you have either docker or podman installed, just running `make docker-make` will take care of everything for you and build the images.
