FROM alpine:3.4
MAINTAINER mail@racktear.com

RUN addgroup -S tarantool \
    && adduser -S -G tarantool tarantool \
    && apk add --no-cache 'su-exec>=0.2'

ENV TARANTOOL_VERSION=1.7.2-287-g085f6e4 \
    TARANTOOL_DOWNLOAD_URL=https://github.com/tarantool/tarantool.git \
    TARANTOOL_INSTALL_LUADIR=/usr/local/share/tarantool \
    LUAROCKS_URL=http://keplerproject.github.io/luarocks/releases/luarocks-2.3.0.tar.gz \
    LUAROCK_AVRO_SCHEMA_REPO=https://github.com/tarantool/avro-schema.git \
    LUAROCK_AVRO_SCHEMA_TAG=b49efa8 \
    LUAROCK_EXPIRATIOND_REPO=https://github.com/tarantool/expirationd.git \
    LUAROCK_EXPIRATIOND_TAG=9ec22b6 \
    LUAROCK_QUEUE_REPO=https://github.com/tarantool/queue.git \
    LUAROCK_QUEUE_TAG=9796515 \
    LUAROCK_CONNPOOL_REPO=https://github.com/tarantool/connpool.git \
    LUAROCK_CONNPOOL_TAG=685af44 \
    LUAROCK_SHARD_REPO=https://github.com/tarantool/shard.git \
    LUAROCK_SHARD_TAG=278b906 \
    LUAROCK_HTTP_REPO=https://github.com/tarantool/http.git \
    LUAROCK_HTTP_TAG=4486de9 \
    LUAROCK_PG_REPO=https://github.com/tarantool/pg.git \
    LUAROCK_PG_TAG=43a7130 \
    LUAROCK_MYSQL_REPO=https://github.com/tarantool/mysql.git \
    LUAROCK_MYSQL_TAG=1c15d30 \
    LUAROCK_MEMCACHED_REPO=https://github.com/tarantool/memcached.git \
    LUAROCK_MEMCACHED_TAG=c927626 \
    LUAROCK_TARANTOOL_PROMETHEUS_REPO=https://github.com/tarantool/prometheus.git \
    LUAROCK_TARANTOOL_PROMETHEUS_TAG=0654304 \
    LUAROCK_TARANTOOL_CURL_REPO=https://github.com/tarantool/curl.git \
    LUAROCK_TARANTOOL_CURL_TAG=900b3fd \
    LUAROCK_MQTT_REPO=https://github.com/tarantool/mqtt.git \
    LUAROCK_MQTT_TAG=238fd2e \
    LUAROCK_TARANTOOL_GIS_REPO=https://github.com/tarantool/gis.git \
    LUAROCK_TARANTOOL_GIS_TAG=25209fc

RUN set -x \
    && apk add --no-cache --virtual .run-deps \
        libstdc++ \
        readline \
        openssl \
        yaml \
        lz4 \
        binutils \
        ncurses \
        libgomp \
        lua \
        curl \
        tar \
        zip \
    && apk add --no-cache --virtual .build-deps \
        perl \
        gcc \
        g++ \
        cmake \
        readline-dev \
        openssl-dev \
        yaml-dev \
        lz4-dev \
        binutils-dev \
        ncurses-dev \
        lua-dev \
        musl-dev \
        make \
        git \
    && : "---------- tarantool ----------" \
    && mkdir -p /usr/src/tarantool \
    && git clone "$TARANTOOL_DOWNLOAD_URL" /usr/src/tarantool \
    && git -C /usr/src/tarantool checkout "$TARANTOOL_VERSION" \
    && git -C /usr/src/tarantool submodule update --init --recursive \
    && (cd /usr/src/tarantool; \
       cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo\
             -DENABLE_BUNDLED_LIBYAML:BOOL=OFF\
             -DENABLE_BACKTRACE:BOOL=ON\
             -DENABLE_DIST:BOOL=ON\
             .) \
    && make -C /usr/src/tarantool -j\
    && make -C /usr/src/tarantool install \
    && make -C /usr/src/tarantool clean \
    && : "---------- small ----------" \
    && (cd /usr/src/tarantool/src/lib/small; \
        cmake -DCMAKE_INSTALL_PREFIX=/usr \
              -DCMAKE_INSTALL_LIBDIR=lib \
              -DCMAKE_BUILD_TYPE=RelWithDebInfo \
              .) \
    && make -C /usr/src/tarantool/src/lib/small \
    && make -C /usr/src/tarantool/src/lib/small install \
    && make -C /usr/src/tarantool/src/lib/small clean \
    && : "---------- msgpuck ----------" \
    && (cd /usr/src/tarantool/src/lib/msgpuck; \
        cmake -DCMAKE_INSTALL_PREFIX=/usr \
              -DCMAKE_INSTALL_LIBDIR=lib \
              -DCMAKE_BUILD_TYPE=RelWithDebInfo \
              .) \
    && make -C /usr/src/tarantool/src/lib/msgpuck \
    && make -C /usr/src/tarantool/src/lib/msgpuck install \
    && make -C /usr/src/tarantool/src/lib/msgpuck clean \
    && : "---------- luarocks ----------" \
    && wget -O luarocks.tar.gz "$LUAROCKS_URL" \
    && mkdir -p /usr/src/luarocks \
    && tar -xzf luarocks.tar.gz -C /usr/src/luarocks --strip-components=1 \
    && (cd /usr/src/luarocks; \
        ./configure; \
        make build; \
        make install) \
    && rm -r /usr/src/luarocks \
    && rm -rf /usr/src/tarantool \
    && : "---------- remove build deps ----------" \
    && apk del .build-deps

COPY luarocks-config.lua /usr/local/etc/luarocks/config-5.1.lua

RUN set -x \
    && apk add --no-cache --virtual .run-deps \
        mariadb-client-libs \
        libpq \
        cyrus-sasl \
        libcurl \
        mosquitto-libs \
    && apk add --no-cache --virtual .build-deps \
        git \
        cmake \
        make \
        coreutils \
        gcc \
        g++ \
        postgresql-dev \
        lua-dev \
        musl-dev \
        cyrus-sasl-dev \
        curl-dev \
        mosquitto-dev \
    && mkdir -p /rocks \
    && : "---------- proj (for gis module) ----------" \
    && wget -O proj.tar.gz http://download.osgeo.org/proj/proj-4.9.3.tar.gz \
    && mkdir -p /usr/src/proj \
    && tar -xzf proj.tar.gz -C /usr/src/proj --strip-components=1 \
    && (cd /usr/src/proj; \
        ./configure; \
        make; \
        make install) \
    && rm -r /usr/src/proj \
    && rm -rf /usr/src/proj \
    && : "---------- geos (for gis module) ----------" \
    && wget -O geos.tar.bz2 http://download.osgeo.org/geos/geos-3.6.0.tar.bz2 \
    && mkdir -p /usr/src/geos \
    && tar -xjf geos.tar.bz2 -C /usr/src/geos --strip-components=1 \
    && (cd /usr/src/geos; \
        ./configure; \
        make; \
        make install) \
    && rm -r /usr/src/geos \
    && rm -rf /usr/src/geos \
    && : "---------- luarocks ----------" \
    && luarocks install lua-term \
    && : "avro" \
    && git clone $LUAROCK_AVRO_SCHEMA_REPO /rocks/avro \
    && git -C /rocks/avro checkout $LUAROCK_AVRO_SCHEMA_TAG \
    && (cd /rocks/avro && luarocks make *rockspec) \
    && : "expirationd" \
    && git clone $LUAROCK_EXPIRATIOND_REPO /rocks/expirationd \
    && git -C /rocks/expirationd checkout $LUAROCK_EXPIRATIOND_TAG \
    && (cd /rocks/expirationd && luarocks make *rockspec) \
    && : "queue" \
    && git clone $LUAROCK_QUEUE_REPO /rocks/queue \
    && git -C /rocks/queue checkout $LUAROCK_QUEUE_TAG \
    && (cd /rocks/queue && luarocks make *rockspec) \
    && : "connpool" \
    && git clone $LUAROCK_CONNPOOL_REPO /rocks/connpool \
    && git -C /rocks/connpool checkout $LUAROCK_CONNPOOL_TAG \
    && (cd /rocks/connpool && luarocks make *rockspec) \
    && : "shard" \
    && git clone $LUAROCK_SHARD_REPO /rocks/shard \
    && git -C /rocks/shard checkout $LUAROCK_SHARD_TAG \
    && (cd /rocks/shard && luarocks make *rockspec) \
    && : "http" \
    && git clone $LUAROCK_HTTP_REPO /rocks/http \
    && git -C /rocks/http checkout $LUAROCK_HTTP_TAG \
    && (cd /rocks/http && luarocks make *rockspec) \
    && : "pg" \
    && git clone $LUAROCK_PG_REPO /rocks/pg \
    && git -C /rocks/pg checkout $LUAROCK_PG_TAG \
    && (cd /rocks/pg && luarocks make *rockspec) \
    && : "mysql" \
    && git clone $LUAROCK_MYSQL_REPO /rocks/mysql \
    && git -C /rocks/mysql checkout $LUAROCK_MYSQL_TAG \
    && (cd /rocks/mysql && luarocks make *rockspec) \
    && : "memcached" \
    && git clone $LUAROCK_MEMCACHED_REPO /rocks/memcached \
    && git -C /rocks/memcached checkout $LUAROCK_MEMCACHED_TAG \
    && (cd /rocks/memcached && luarocks make *rockspec) \
    && : "prometheus" \
    && git clone $LUAROCK_TARANTOOL_PROMETHEUS_REPO /rocks/prometheus \
    && git -C /rocks/prometheus checkout $LUAROCK_TARANTOOL_PROMETHEUS_TAG \
    && (cd /rocks/prometheus && luarocks make *rockspec) \
    && : "curl" \
    && git clone $LUAROCK_TARANTOOL_CURL_REPO /rocks/curl \
    && git -C /rocks/curl checkout $LUAROCK_TARANTOOL_CURL_TAG \
    && (cd /rocks/curl && luarocks make *rockspec) \
    && : "mqtt" \
    && git clone $LUAROCK_MQTT_REPO /rocks/mqtt \
    && git -C /rocks/mqtt checkout $LUAROCK_MQTT_TAG \
    && (cd /rocks/mqtt && luarocks make *rockspec) \
    && : "gis" \
    && git clone $LUAROCK_TARANTOOL_GIS_REPO /rocks/gis \
    && git -C /rocks/gis checkout $LUAROCK_TARANTOOL_GIS_TAG \
    && (cd /rocks/gis && luarocks make *rockspec) \
    && : "---------- remove build deps ----------" \
    && apk del .build-deps \
    && rm -rf /rocks


RUN mkdir -p /var/lib/tarantool \
    && chown tarantool:tarantool /var/lib/tarantool \
    && mkdir -p /opt/tarantool \
    && chown tarantool:tarantool /opt/tarantool \
    && mkdir -p /var/run/tarantool \
    && chown tarantool:tarantool /var/run/tarantool \
    && mkdir /etc/tarantool \
    && chown tarantool:tarantool /etc/tarantool

VOLUME /var/lib/tarantool
WORKDIR /opt/tarantool

COPY tarantool-entrypoint.lua /usr/local/bin/
COPY tarantool_set_config.lua /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin/
COPY tarantool_is_up /usr/local/bin/
COPY tarantool.default /usr/local/etc/default/tarantool

RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3301
CMD [ "tarantool" ]

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 7.3.0

RUN adduser -D -u 1000 node \
    && apk add --no-cache \
        libstdc++ \
    && apk add --no-cache --virtual .build-deps \
        binutils-gold \
        curl \
        g++ \
        gcc \
        gnupg \
        libgcc \
        linux-headers \
        make \
        python \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  ; do \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
  done \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.gz" \
    && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION.tar.gz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -zxf "node-v$NODE_VERSION.tar.gz" \
    && cd "node-v$NODE_VERSION" \
    && ./configure \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && apk del .build-deps \
    && cd .. \
    && rm -Rf "node-v$NODE_VERSION" \
    && rm "node-v$NODE_VERSION.tar.gz" SHASUMS256.txt.asc SHASUMS256.txt

COPY node/server.js /opt/node/

EXPOSE 8000

CMD [ "/opt/node/node server.js" ]