# SPDX-FileCopyrightText: 2024 Victor Dahmen
# SPDX-License-Identifier: AGPL-3.0-only

ZABBIX_VER := 7.0.0 6.4.17 6.0.32
PHP_VER := 8.3.8
UNIT_VER := 1.32.1-1
ENTRYPOINT_VER := 0.1.0
ARCH := x86_64
IMAGE := comprime/zabbix-web-unit
SIGNING_KEY := melange.rsa
MELANGE_RUNNER := bubblewrap
SRC_DIR := ./src
CACHE := ./cache
MELANGE_CACHE := $(CACHE)/melange
APK_CACHE := $(CACHE)/apk
MELANGE_OPTS := \
	--runner=$(MELANGE_RUNNER) \
	--apk-cache-dir=$(APK_CACHE) \
	--cache-dir=$(MELANGE_CACHE) \
	--arch=$(ARCH) \
	--signing-key=$(SIGNING_KEY)
REPO_OPTS := \
	--keyring-append=$(SIGNING_KEY).pub \
	--repository-append='@local packages'
ifndef DOCKER
ifneq ($(shell which docker),)
DOCKER := docker
else ifneq ($(shell which podman),)
DOCKER := podman
endif
endif


.PHONY: all
all: images

.PHONY: docker-make
docker-make: $(SIGNING_KEY)
	@$(DOCKER) build . -f builder.Dockerfile -t zabbix-web-builder
	@$(DOCKER) run --rm -it \
		--cap-add=SYS_ADMIN --security-opt=seccomp=unconfined \
		--tmpfs=/var/tmp \
		--user=$(shell id -u):$(shell id -g) \
		-v=${PWD}:/work:ro \
		-v=${PWD}/$(SIGNING_KEY).pub:/etc/apk/keys/$(SIGNING_KEY).pub:ro \
		-v=${PWD}/packages:/work/packages \
		-v=${PWD}/images:/work/images \
		-v=${PWD}/cache:/work/cache \
		-w=/work zabbix-web-builder \
			make all

$(SIGNING_KEY) $(SIGNING_KEY).pub:
ifneq ($(shell which melange),)
	@melange keygen $(SIGNING_KEY)
else
	@$(DOCKER) build . -f builder.Dockerfile -t zabbix-web-builder
	@$(DOCKER) run --rm -it -v ${PWD}:/work -w /work zabbix-web-builder \
		make $(SIGNING_KEY)
endif


############
# Packages #
############

PACKAGES = \
	packages/$(ARCH)/docker-entrypoint-compat-$(ENTRYPOINT_VER)-r0.apk \
	packages/$(ARCH)/php-8.3-$(PHP_VER)-r1.apk \
	packages/$(ARCH)/unit-$(UNIT_VER)-r0.apk

ENTRYPOINT_CONTENTS_FILTER = %.yaml src/maintenance.inc.php src/zabbix.conf.php
ENTRYPOINT_CONTENTS = $(filter-out $(ENTRYPOINT_CONTENTS_FILTER),$(wildcard src/*))
.PRECIOUS: packages/$(ARCH)/docker-entrypoint-compat-$(ENTRYPOINT_VER)-r0.apk
packages/$(ARCH)/docker-entrypoint-compat-$(ENTRYPOINT_VER)-r0.apk: src/docker-entrypoint.melange.yaml $(ENTRYPOINT_CONTENTS) $(SIGNING_KEY)
	@melange build \
		src/docker-entrypoint.melange.yaml \
		$(MELANGE_OPTS) \
		--source-dir=$(SRC_DIR)


ZABBIX_WEB_CONTENTS = src/maintenance.inc.php src/zabbix.conf.php
.PRECIOUS: packages/$(ARCH)/zabbix-web-%-r0.apk
packages/$(ARCH)/zabbix-web-%-r0.apk: src/zabbix-web.melange.yaml $(ZABBIX_WEB_CONTENTS) $(SIGNING_KEY)
	$(eval TMPDIR := $(shell mktemp -d -t zw-XXXXXX))
	$(eval MELFILE := $(TMPDIR)/$(notdir $<))
	@cp $< $(MELFILE)
	@if [ "$$(melange package-version $(MELFILE))" != "zabbix-web-$*-r0" ]; then melange bump $(MELFILE) $*; fi
	@melange build \
		$(MELFILE) \
		$(MELANGE_OPTS) \
		--source-dir=$(SRC_DIR)
	@rm -rf $(TMPDIR)


.PRECIOUS: packages/$(ARCH)/php-8.3-%-r1.apk
packages/$(ARCH)/php-8.3-%-r1.apk: src/php-8.3.melange.yaml $(SIGNING_KEY)
	$(eval TMPDIR := $(shell mktemp -d -t zw-XXXXXX))
	$(eval MELFILE := $(TMPDIR)/$(notdir $<))
	@cp $< $(MELFILE)
	@if [ "$$(melange package-version $(MELFILE))" != "php-8.3-$*-r1" ]; then melange bump $(MELFILE) $*; fi
	@melange build \
		$(MELFILE) \
		$(MELANGE_OPTS)
	@rm -rf $(TMPDIR)


.PRECIOUS: packages/$(ARCH)/unit-%-r0.apk
packages/$(ARCH)/unit-%-r0.apk: src/unit.melange.yaml $(SIGNING_KEY) $(SIGNING_KEY).pub
	$(eval TMPDIR := $(shell mktemp -d -t zw-XXXXXX))
	$(eval MELFILE := $(TMPDIR)/$(notdir $<))
	@cp $< $(MELFILE)
	@if [ "$$(melange package-version $(MELFILE))" != "unit-$*-r0" ]; then melange bump $(MELFILE) $*; fi
	@melange build \
		$(MELFILE) \
		$(MELANGE_OPTS) \
		$(REPO_OPTS)
	@rm -rf $(TMPDIR)


##########
# Images #
##########

.PRECIOUS: images/zabbix-web-unit.%
images/zabbix-web-unit.%: src/zabbix-web-unit.apko.yaml $(PACKAGES) packages/$(ARCH)/zabbix-web-%-r0.apk $(SIGNING_KEY).pub
	@mkdir images/zabbix-web-unit.$*/
	@apko build \
		src/zabbix-web-unit.apko.yaml \
		--cache-dir=$(APK_CACHE) \
		--arch=$(ARCH) \
		$(REPO_OPTS) \
		--package-append='zabbix-web=$*@local' \
		--sbom=false \
		$(IMAGE):$* \
		images/zabbix-web-unit.$*/


.PRECIOUS: images/zabbix-web-unit.%
images/zabbix-web-unit.%.tar: images/zabbix-web-unit.%
	@skopeo copy \
		oci:$< \
		docker-archive:$<.tar \
		--additional-tag $(IMAGE):$* \
		--additional-tag $(IMAGE):wolfi-$*


.PHONY: images
images: $(foreach ver,$(ZABBIX_VER),images/zabbix-web-unit.$(ver).tar)
