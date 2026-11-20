# syntax=docker/dockerfile:1.7

ARG WOLFI_BASE=cgr.dev/chainguard/wolfi-base:latest
ARG STATIC_IMAGE=cgr.dev/chainguard/static:latest

FROM ${WOLFI_BASE} AS build

ARG TARGETARCH

RUN apk add --no-cache build-base

WORKDIR /src

COPY 3rd ./3rd
COPY manifest.json httplib.c3i httplib.c3 LICENSE ./

RUN g++ -std=c++23 -O2 -fPIC -I3rd -c 3rd/httplibshim.cpp -o httplibshim.o \
    && ar rcs libhttplibshim.a httplibshim.o

RUN printf '%s\n' \
        '#include <httplibshim.hpp>' \
        'int main() { Server *s = server_create(); if (!s) return 1; server_destroy(s); return 0; }' \
        > smoke.cpp \
    && g++ -std=c++23 -I3rd smoke.cpp -L. -lhttplibshim -o smoke \
    && ./smoke

RUN case "${TARGETARCH}" in \
        amd64) c3_target=linux-x64 ;; \
        arm64) c3_target=linux-aarch64 ;; \
        *) echo "unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && lib=/out/usr/lib/c3/httplib.c3l \
    && mkdir -p /out/usr/include "$lib/$c3_target" /out/usr/share/licenses/httplib.c3l \
    && cp 3rd/httplib.h 3rd/httplibshim.hpp /out/usr/include/ \
    && cp libhttplibshim.a /out/usr/lib/ \
    && cp manifest.json httplib.c3i httplib.c3 "$lib/" \
    && cp libhttplibshim.a "$lib/$c3_target/" \
    && cp LICENSE /out/usr/share/licenses/httplib.c3l/

FROM ${STATIC_IMAGE}

COPY --from=build /out/usr/ /usr/

LABEL org.opencontainers.image.title="httplib.c3l" \
      org.opencontainers.image.description="C3 bindings for cpp-httplib: headers, libhttplibshim.a and /usr/lib/c3/httplib.c3l" \
      org.opencontainers.image.source="https://github.com/gcca/httplib.c3l" \
      org.opencontainers.image.version="0.1.0" \
      org.opencontainers.image.licenses="AGPL-3.0-only"
