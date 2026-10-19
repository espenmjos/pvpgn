#
# PvPGN server: bnetd, d2cs and d2dbs in one image.
# Pick the daemon with the container command: bnetd | d2cs | d2dbs
#

ARG UBUNTU_VERSION=24.04

############################################################
# Stage 1: build
############################################################
FROM ubuntu:${UBUNTU_VERSION} AS build

ARG PVPGN_VERSION=1.99.8.0.0-rc1-PRO
ARG WITH_LUA=true
ARG WITH_MYSQL=true
ARG WITH_SQLITE3=true

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates wget build-essential cmake \
      zlib1g-dev libcurl4-openssl-dev \
      liblua5.1-0-dev libmysqlclient-dev libsqlite3-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN wget -q -O- https://github.com/pvpgn/pvpgn-server/archive/refs/tags/${PVPGN_VERSION}.tar.gz \
  | tar xz --strip-components=1

RUN cmake -S . -B out \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DWITH_LUA=${WITH_LUA} -DWITH_MYSQL=${WITH_MYSQL} -DWITH_SQLITE3=${WITH_SQLITE3} \
 && cmake --build out -j"$(nproc)" \
 && cmake --install out

############################################################
# Stage 2: runtime
############################################################
FROM ubuntu:${UBUNTU_VERSION}

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates zlib1g libcurl4t64 liblua5.1-0 libmysqlclient21 libsqlite3-0 \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --system --create-home --home-dir /var/lib/pvpgn pvpgn

COPY --from=build /usr/local/sbin/ /usr/local/sbin/
COPY --from=build /usr/local/bin/ /usr/local/bin/
# Pristine defaults, copied into empty volumes on first start
COPY --from=build /usr/local/etc/pvpgn/ /usr/local/share/pvpgn/defaults/etc/
COPY --from=build /usr/local/var/pvpgn/ /usr/local/share/pvpgn/defaults/var/
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod 755 /usr/local/bin/entrypoint.sh \
 && mkdir -p /usr/local/etc/pvpgn /usr/local/var/pvpgn

VOLUME ["/usr/local/etc/pvpgn", "/usr/local/var/pvpgn"]

# bnetd 6112 tcp/udp, d2cs 6113, d2dbs 6114
EXPOSE 6112 6112/udp 6113 6114

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bnetd"]
