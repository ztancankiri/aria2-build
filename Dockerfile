FROM hurlenko/aria2-ariang AS build

ENV LOCAL_DIR /local

RUN apk --no-cache update \
    && apk --no-cache add gcc g++ make binutils autoconf automake libtool pkgconfig git curl dpkg-dev gettext cppunit-dev libxml2-dev libgcrypt-dev linux-headers lzip

RUN mkdir /zlib && cd /zlib \
    && curl -Ls -o - 'https://www.zlib.net/fossils/zlib-1.2.11.tar.gz' | tar xzf - --strip-components=1 \
    && ./configure --static --libdir=$LOCAL_DIR/lib \
    && make -s && make -s install

RUN mkdir /expat && cd /expat \
    && curl -Ls -o - 'https://github.com/libexpat/libexpat/releases/download/R_2_5_0/expat-2.5.0.tar.gz' | tar xzf - --strip-components=1 \
    && ./configure --enable-shared=no --enable-static=yes --prefix=${LOCAL_DIR} \
    && make -s && make -s install

RUN mkdir /c-ares && cd /c-ares \
    && curl -Ls -o - 'http://c-ares.haxx.se/download/c-ares-1.10.0.tar.gz' | tar xzf - --strip-components=1 \
    && ./configure --enable-shared=no --enable-static=yes --prefix=${LOCAL_DIR} \
    && make -s && make -s install

RUN mkdir /gmp && cd /gmp \
    && curl -Ls -o - 'https://gmplib.org/download/gmp/gmp-6.1.0.tar.lz' | lzip -d | tar xf - --strip-components=1 \
    && ./configure --disable-shared --enable-static --prefix=$LOCAL_DIR --disable-cxx --enable-fat \
    && make -s && make -s install

RUN mkdir /sqlite && cd /sqlite \
    && curl -Ls -o - 'https://www.sqlite.org/2016/sqlite-autoconf-3100100.tar.gz' | tar xzf - --strip-components=1 \
    && ./configure --disable-shared --enable-static --prefix=$LOCAL_DIR \
    && make -s && make -s install

RUN mkdir /openssl && cd /openssl \
    && curl -Ls -o - 'https://www.openssl.org/source/openssl-1.1.1l.tar.gz' | tar xzf - --strip-components=1 \
    && ./config --prefix=${LOCAL_DIR} --openssldir=${LOCAL_DIR}/ssl no-shared \
    && make -s && make -s install

RUN mkdir /aria && cd /aria \
    && curl -Ls -o - 'https://github.com/aria2/aria2/releases/download/release-1.36.0/aria2-1.36.0.tar.gz' | tar xzf - --strip-components=1 \
    && ./configure \
    --disable-bittorrent --disable-metalink \
    --without-gnutls --without-libxml2 \
    --with-openssl --with-openssl-prefix=${LOCAL_DIR} \
    --with-libz --with-libz-prefix=${LOCAL_DIR} \
    --with-libexpat --with-libexpat-prefix=${LOCAL_DIR} \
    --with-sqlite3 --with-sqlite3-prefix=${LOCAL_DIR} \
    --with-libcares --with-libcares-prefix=${LOCAL_DIR} \
    --prefix=${LOCAL_DIR} \
    LDFLAGS="-L$LOCAL_DIR/lib" PKG_CONFIG_PATH="$LOCAL_DIR/lib/pkgconfig" \
    ARIA2_STATIC=yes \
    && make -s && make -s install-strip

FROM hurlenko/aria2-ariang

COPY --from=build /local/bin/aria2c /usr/local/bin/
RUN mkdir -p /aria2/conf-copy && \
    echo "enable-rpc=true" > /aria2/conf-copy/aria2.conf && \
    echo "rpc-allow-origin-all=true" >> /aria2/conf-copy/aria2.conf && \
    echo "rpc-listen-all=true" >> /aria2/conf-copy/aria2.conf && \
    echo "disable-ipv6=true" >> /aria2/conf-copy/aria2.conf && \
    echo "max-concurrent-downloads=5" >> /aria2/conf-copy/aria2.conf && \
    echo "continue=true" >> /aria2/conf-copy/aria2.conf && \
    echo "max-connection-per-server=5" >> /aria2/conf-copy/aria2.conf && \
    echo "min-split-size=10M" >> /aria2/conf-copy/aria2.conf && \
    echo "split=10" >> /aria2/conf-copy/aria2.conf && \
    echo "max-overall-download-limit=0" >> /aria2/conf-copy/aria2.conf && \
    echo "max-download-limit=0" >> /aria2/conf-copy/aria2.conf && \
    echo "dir=/aria2/data" >> /aria2/conf-copy/aria2.conf && \
    echo "file-allocation=prealloc" >> /aria2/conf-copy/aria2.conf && \
    echo "console-log-level=notice" >> /aria2/conf-copy/aria2.conf && \
    echo "input-file=/aria2/conf/aria2.session" >> /aria2/conf-copy/aria2.conf && \
    echo "save-session=/aria2/conf/aria2.session" >> /aria2/conf-copy/aria2.conf && \
    echo "save-session-interval=10" >> /aria2/conf-copy/aria2.conf