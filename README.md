# Zabbix Web Unit

This repo contains files necesary to build a container image for the Zabbix Frontend using the NGINX Unit Application runtime.
This is intended as drop in replacement for the zabbix/zabbix-web-[apache,nginx]-mysql images.

The two big changes:

- The image is built on the Wolfi (un)distribution, which means it has a small footprint.
- The image uses NGINX Unit instead of using PHP-FPM & NGINX / Apache HTTP, which comes with better thoughput and removes reliance on supervisord.

Apart from those two major changes, it also includes some smaller fixes:

- docker-entrypoint.sh script doesn't require bash
- docker-entrypoint.sh doesn't tests its DB connection using a php script, (dbcheck.php), thus doesn't depend on mysql-admin command.
- additional flags for enabling php-opcache and preloading, (preload.php), thus increasing throughput and lowering latencies.

## Docker images

Container images have been published to docker hub and can be found [here][dh-repo]

Following image tags currently exist:

| Zabbix Version | Image repo                          | Tags                                                                              |
|----------------|-------------------------------------|-----------------------------------------------------------------------------------|
| 6.0.31         | [comprime/zabbix-web-unit][dh-tags] | [6.0-latest][dh-6.0-latest], [wolfi-6.0.31][dh-wolfi-6.0.31], [6.0.31][dh-6.0.31] |
| 6.4.16         | [comprime/zabbix-web-unit][dh-tags] | [6.4-latest][dh-6.4-latest], [wolfi-6.4.16][dh-wolfi-6.4.16], [6.4.16][dh-6.4.16] |
| 7.0.0          | [comprime/zabbix-web-unit][dh-tags] | [7.0-latest][dh-7.0-latest], [wolfi-7.0.0][dh-wolfi-7.0.0], [7.0.0][dh-7.0.0]     |

[dh-repo]: https://hub.docker.com/r/comprime/zabbix-web-unit
[dh-tags]: https://hub.docker.com/r/comprime/zabbix-web-unit/tags
[dh-6.0-latest]: https://hub.docker.com/layers/comprime/zabbix-web-unit/6.0-latest/images/sha256-b0c595727487a5761b0c2d5cd28b05c62683cdc9a13855aa9a00449e03fe340a
[dh-6.4-latest]: https://hub.docker.com/layers/comprime/zabbix-web-unit/6.4-latest/images/sha256-5ca8667ba726e62c6652423010bbffac537d1964d63a7d1a6fa253187b351f74
[dh-7.0-latest]: https://hub.docker.com/layers/comprime/zabbix-web-unit/7.0-latest/images/sha256-848bee4da075e260e8ffdb42fd1ffe6b7afd1eb88a7630daaf1f2265006d8850
[dh-6.0.31]: https://hub.docker.com/layers/comprime/zabbix-web-unit/6.0.31/images/sha256-b0c595727487a5761b0c2d5cd28b05c62683cdc9a13855aa9a00449e03fe340a
[dh-6.4.16]: https://hub.docker.com/layers/comprime/zabbix-web-unit/6.4.16/images/sha256-5ca8667ba726e62c6652423010bbffac537d1964d63a7d1a6fa253187b351f74
[dh-7.0.0]:  https://hub.docker.com/layers/comprime/zabbix-web-unit/7.0.0/images/sha256-848bee4da075e260e8ffdb42fd1ffe6b7afd1eb88a7630daaf1f2265006d8850
[dh-wolfi-6.0.31]: https://hub.docker.com/layers/comprime/zabbix-web-unit/wolfi-6.0.31/images/sha256-b0c595727487a5761b0c2d5cd28b05c62683cdc9a13855aa9a00449e03fe340a
[dh-wolfi-6.4.16]: https://hub.docker.com/layers/comprime/zabbix-web-unit/wolfi-6.4.16/images/sha256-5ca8667ba726e62c6652423010bbffac537d1964d63a7d1a6fa253187b351f74
[dh-wolfi-7.0.0]:  https://hub.docker.com/layers/comprime/zabbix-web-unit/wolfi-7.0.0/images/sha256-848bee4da075e260e8ffdb42fd1ffe6b7afd1eb88a7630daaf1f2265006d8850

## Build instructions

Image is built using [melange](https://github.com/chainguard-dev/melange), [apko](https://github.com/chainguard-dev/apko), [skopeo](https://github.com/containers/skopeo), and [make](https://www.gnu.org/software/make/).
Melange then has a dependency on [bubblewrap](https://github.com/containers/bubblewrap).

If you have either docker or podman installed, just running `make docker-make` will take care of everything for you and build the images.
