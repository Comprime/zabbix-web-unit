# SPDX-FileCopyrightText: 2024 Victor Dahmen
# SPDX-License-Identifier: AGPL-3.0-only

ZABBIX_VER := 7.0.0
PHP_VER := 8.3.8
UNIT_VER := 1.32.1-1
ENTRYPOINT_VER := 0.1.0
ARCH := x86_64
IMAGE := comprime/zabbix-web-unit:$(ZABBIX_VER)-latest
SIGNING_KEY := melange.rsa

.PHONY: all
all: images

.PHONY:
docker-make: $(SIGNING_KEY)
	docker build . -f builder.Dockerfile -t zabbix-web-builder
	docker run --rm -it \
		--cap-add SYS_ADMIN --security-opt seccomp=unconfined \
		--tmpfs /var/tmp \
		-v ${PWD}:/work:ro -v ${PWD}/$(SIGNING_KEY).pub:/etc/apk/keys/$(SIGNING_KEY).pub:ro \
		-v ${PWD}/packages:/work/packages \
		-v ${PWD}/images:/work/images \
		-v ${PWD}/sboms:/work/sboms \
		-w /work zabbix-web-builder \
			make images

$(SIGNING_KEY):
	docker build . -f builder.Dockerfile -t zabbix-web-builder
	docker run --rm -it -v ${PWD}:/work -w /work zabbix-web-builder \
		make $(SIGNING_KEY).docker

.PHONY: $(SIGNING_KEY).docker
$(SIGNING_KEY).docker:
	melange keygen $(SIGNING_KEY)

packages/$(ARCH)/docker-entrypoint-$(ENTRYPOINT_VER)-r0.apk: $(SIGNING_KEY) src/docker-entrypoint.melange.yaml
	melange build \
		src/docker-entrypoint.melange.yaml \
		--source-dir=src \
		--arch=$(ARCH) \
		--runner=bubblewrap \
		--signing-key=$(SIGNING_KEY)

packages/$(ARCH)/zabbix-web-$(ZABBIX_VER)-r0.apk: $(SIGNING_KEY) src/zabbix-web.melange.yaml
	melange build \
		src/zabbix-web.melange.yaml \
		--source-dir=src \
		--arch=$(ARCH) \
		--runner=bubblewrap \
		--signing-key=$(SIGNING_KEY)

packages/$(ARCH)/php-8.3-$(PHP_VER)-r1.apk: $(SIGNING_KEY) src/php-8.3.melange.yaml
	melange build \
		src/php-8.3.melange.yaml \
		--arch=$(ARCH) \
		--runner=bubblewrap \
		--signing-key=$(SIGNING_KEY)

packages/$(ARCH)/unit-$(UNIT_VER)-r0.apk: packages/$(ARCH)/php-8.3-$(PHP_VER)-r1.apk $(SIGNING_KEY) src/unit.melange.yaml
	melange build \
		src/unit.melange.yaml \
		--arch=$(ARCH) \
		--runner=bubblewrap \
		--keyring-append=$(SIGNING_KEY).pub \
		--repository-append='@local packages' \
		--signing-key $(SIGNING_KEY)

PACKAGES = packages/$(ARCH)/docker-entrypoint-$(ENTRYPOINT_VER)-r0.apk packages/$(ARCH)/zabbix-web-$(ZABBIX_VER)-r0.apk packages/$(ARCH)/php-8.3-$(PHP_VER)-r1.apk packages/$(ARCH)/unit-$(UNIT_VER)-r0.apk

images/zabbix-web-unit.tgz: $(PACKAGES) src/zabbix-web-unit.apko.yaml
	apko build \
		src/zabbix-web-unit.apko.yaml \
		--arch=$(ARCH) \
		--sbom-path sboms/ \
		--keyring-append $(SIGNING_KEY).pub \
		--repository-append='@local packages' \
		$(IMAGE) images/zabbix-web-unit.tgz

.PHONY: images
images: images/zabbix-web-unit.tgz
