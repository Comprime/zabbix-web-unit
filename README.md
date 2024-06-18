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
