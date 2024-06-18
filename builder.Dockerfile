# syntax=docker/dockerfile:1
# SPDX-FileCopyrightText: 2024 Victor Dahmen
# SPDX-License-Identifier: AGPL-3.0-only

FROM chainguard/wolfi-base
RUN --mount=type=cache,target=/var/cache/apk \
    apk add melange apko make
