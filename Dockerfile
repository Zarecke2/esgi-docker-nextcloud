FROM php:8.0-alpine3.15

# RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

ENV PHP_MEMORY_LIMIT 512M
ENV PHP_UPLOAD_LIMIT 512M

# Add basics first
RUN apk update && apk upgrade && apk add \
    bash \
    nano \
    apache2 \
    php8-apache2 \
    libxml2 \
    libpng-dev \
    libjpeg \
    libwebp-dev \
    libzip-dev \
    bzip2 \
    libcurl \
    libgd \
    icu \
    icu-dev \
    zlib-dev \
    curl \
    ca-certificates \
    openssl \
    openssh \
    mercurial \
    subversion \
    php8 \
    php8-json \
    php8-openssl \
    tzdata \
    openntpd \
    unzip \
    mysql-client \
    shadow \
    g++ \
    make

# Setup apache and php
RUN apk add \
    php8-ctype \
    php8-curl \
    php8-dom \
    php8-gd \
    # php8-libxml \
    php8-mbstring \
    php8-posix \
    php8-session \
    php8-xmlreader \
    php8-xmlwriter \
    php8-zip \
    php8-zlib \
    php8-pdo_mysql \
    php8-fileinfo \
    php8-bz2 \
    php8-intl \
    php8-redis \
    php8-pecl-apcu \
    php8-opcache \
    php8-xml \
    php8-exif \
    php8-mysqli \
    php8-bcmath \
    php8-odbc \
    php8-gettext \
    php8-tokenizer \
    php8-pecl-mcrypt \
    php8-pecl-xdebug 
# Problems installing in above stack
RUN apk add php8-simplexml

RUN cp /usr/bin/php8 /usr/bin/php \
    && rm -f /var/cache/apk/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-install -j "$(nproc)" \
    pecl install apcu; \
    pecl install memcached-3.2.0; \
    pecl install redis-5.3.7; \
    pecl install imagick-3.7.0; \
    \
    docker-php-ext-enable \
    apcu \
    memcached \
    redis \
    imagick \
    ;



# Add apache to run and configure
RUN sed -i "s/#LoadModule\ rewrite_module/LoadModule\ rewrite_module/" /etc/apache2/httpd.conf \
    && sed -i "s/#LoadModule\ session_module/LoadModule\ session_module/" /etc/apache2/httpd.conf \
    && sed -i "s/#LoadModule\ session_cookie_module/LoadModule\ session_cookie_module/" /etc/apache2/httpd.conf \
    && sed -i "s/#LoadModule\ session_crypto_module/LoadModule\ session_crypto_module/" /etc/apache2/httpd.conf \
    && sed -i "s/#LoadModule\ deflate_module/LoadModule\ deflate_module/" /etc/apache2/httpd.conf

# set recommended PHP.ini settings

RUN sed -i "s/\;\?\\s\?cgi.fix_pathinfo\\s\?=\\s\?.*/cgi.fix_pathinfo = 0/" /etc/php8/php.ini

# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    } > /etc/php8/conf.d/opcache-recommended.ini

RUN { \
    echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
    echo 'display_errors = Off'; \
    echo 'display_startup_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'error_log = /dev/stderr'; \
    echo 'log_errors_max_len = 1024'; \
    echo 'ignore_repeated_errors = On'; \
    echo 'ignore_repeated_source = Off'; \
    echo 'html_errors = Off'; \
    } > /etc/php8/conf.d/error-logging.ini

RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.interned_strings_buffer=16'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.save_comments=1'; \
    echo 'opcache.revalidate_freq=60'; \
    } > "${PHP_INI_DIR}/conf.d/opcache-recommended.ini"; \
    \
    echo 'apc.enable_cli=1' >> "${PHP_INI_DIR}/conf.d/docker-php-ext-apcu.ini"; \
    \
    { \
    echo 'memory_limit=${PHP_MEMORY_LIMIT}'; \
    echo 'upload_max_filesize=${PHP_UPLOAD_LIMIT}'; \
    echo 'post_max_size=${PHP_UPLOAD_LIMIT}'; \
    } > "${PHP_INI_DIR}/conf.d/nextcloud.ini"; \
    \
    mkdir /var/www/data; \
    chown -R www-data:root /var/www; \
    chmod -R g=u /var/www


VOLUME /var/www/html

RUN a2enmod headers rewrite remoteip ;\
    {\
    echo RemoteIPHeader X-Real-IP ;\
    echo RemoteIPTrustedProxy 10.0.0.0/8 ;\
    echo RemoteIPTrustedProxy 172.16.0.0/12 ;\
    echo RemoteIPTrustedProxy 192.168.0.0/16 ;\
    } > /etc/apache2/conf-available/remoteip.conf;\
    a2enconf remoteip

ENV NEXTCLOUD_VERSION 22.2.10

RUN set -ex; \
    apk update; \
    apk add \
    gnupg \
    gnupg \
    curl -fsSL -o nextcloud.tar.bz2 \
    "https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2"; \
    curl -fsSL -o nextcloud.tar.bz2.asc \
    "https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    # gpg key from https://nextcloud.com/nextcloud.asc
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 28806A878AE423A28372792ED75899B9A724937A; \
    gpg --batch --verify nextcloud.tar.bz2.asc nextcloud.tar.bz2; \
    tar -xjf nextcloud.tar.bz2 -C /usr/src/; \
    gpgconf --kill all; \
    rm nextcloud.tar.bz2.asc nextcloud.tar.bz2; \
    rm -rf "$GNUPGHOME" /usr/src/nextcloud/updater; \
    mkdir -p /usr/src/nextcloud/data; \
    mkdir -p /usr/src/nextcloud/custom_apps; \
    chmod +x /usr/src/nextcloud/occ; \
    \
    rm -rf /var/lib/apt/lists/*



# Fix permissions
RUN usermod -u 1000 apache

COPY docker-entrypoint.sh /usr/local/bin/
COPY config/* /usr/src/nextcloud/config/

EXPOSE 80
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["httpd", "-D", "FOREGROUND"]