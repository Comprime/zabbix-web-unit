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

Following image tags currently exist:

| Zabbix Version | Image repo               | Tags                             |
|----------------|--------------------------|----------------------------------|
| 6.0.31         | comprime/zabbix-web-unit | 6.0-latest, wolfi-6.0.31, 6.0.31 |
| 6.4.16         | comprime/zabbix-web-unit | 6.4-latest, wolfi-6.4.16, 6.4.16 |
| 7.0.0          | comprime/zabbix-web-unit | 7.0-latest, wolfi-7.0.0, 7.0.0   |

## Build instructions

Image is built using [melange](https://github.com/chainguard-dev/melange), [apko](https://github.com/chainguard-dev/apko), [skopeo](https://github.com/containers/skopeo), and [make](https://www.gnu.org/software/make/).
Melange then has a dependency on [bubblewrap](https://github.com/containers/bubblewrap).

If you have docker or podman installed, just running `make docker-make` will take care of everything for you and build the images.
