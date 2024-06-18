# SPDX-FileCopyrightText: 2024 Victor Dahmen
# SPDX-License-Identifier: AGPL-3.0-only

ZABBIX_VER = 7.0.0
ARCH = x86_64

.PHONY: all
all: images

.PHONY:
docker-make:
	docker build . -f builder.Dockerfile -t zabbix-web-builder
	docker run --rm -it \
		--cap-add SYS_ADMIN --security-opt seccomp=unconfined \
		--tmpfs /var/tmp \
		-v ${PWD}:/work:ro -v ${PWD}/melange.rsa.pub:/etc/apk/keys/melange.rsa.pub:ro \
		-v ${PWD}/packages:/work/packages \
		-v ${PWD}/images:/work/images \
		-v ${PWD}/sboms:/work/sboms \
		-w /work \
		zabbix-web-builder make 

melange.rsa:
	melange keygen

packages/$(ARCH)/docker-entrypoint-0.1.0-r0.apk: melange.rsa
	melange build \
		src/docker-entrypoint.melange.yaml \
		--source-dir=src \
		--arch=$(ARCH) \
		--runner=bubblewrap \
		--signing-key=melange.rsa

packages/$(ARCH)/zabbix-web-$(ZABBIX_VER)-r0.apk: melange.rsa
	melange build \
		src/zabbix-web.melange.yaml \
		--source-dir=src \
		--arch=$(ARCH) \
		--runner=bubblewrap \
		--signing-key=melange.rsa

packages/$(ARCH)/php-8.3-8.3.8-r1.apk: melange.rsa
	melange build \
		src/php-8.3.melange.yaml \
		--arch=$(ARCH) \
		--runner=bubblewrap \
		--signing-key=melange.rsa

packages/$(ARCH)/unit-1.32.1-1-r0.apk: packages/$(ARCH)/php-8.3-8.3.8-r1.apk melange.rsa
	melange build \
		src/unit.melange.yaml \
		--arch=$(ARCH) \
		--runner=bubblewrap \
		--keyring-append=melange.rsa.pub \
		--repository-append='@local packages' \
		--signing-key melange.rsa

.PHONY: packages
packages: packages/$(ARCH)/docker-entrypoint-0.1.0-r0.apk packages/$(ARCH)/zabbix-web-$(ZABBIX_VER)-r0.apk packages/$(ARCH)/php-8.3-8.3.8-r1.apk packages/$(ARCH)/unit-1.32.1-1-r0.apk

images/zabbix-web-unit.tgz: packages
	apko build \
		src/zabbix-web-unit.apko.yaml \
		--arch=$(ARCH) \
		--sbom-path sboms/ \
		--keyring-append melange.rsa.pub \
		--repository-append='@local packages' \
		ghcr.io/comprime/zabbix-web-unit images/zabbix-web-unit.tgz

.PHONY: images
images: images/zabbix-web-unit.tgz
