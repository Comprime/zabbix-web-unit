# syntax=docker/dockerfile:1
# SPDX-FileCopyrightText: 2024 Victor Dahmen
# SPDX-License-Identifier: AGPL-3.0-only

FROM chainguard/wolfi-base
RUN apk add --no-cache \
        melange apko make skopeo && \
    mkdir /etc/containers/ && \
    echo '{"default":[{"type": "insecureAcceptAnything"}]}' > /etc/containers/policy.json
