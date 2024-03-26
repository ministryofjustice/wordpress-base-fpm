# 26-03-2024
# alpine-3.19 is vulnerable, using alipine3.18
FROM php:8.3-fpm-alpine3.18

RUN apk add --update bash \
    zlib-dev \
    libpng-dev \
    libzip-dev \
    libxml2-dev \
    libjpeg-turbo \
    libgomp \
    imagemagick-dev \
    icu-dev \
    mariadb-client

RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install excimer \
    && docker-php-ext-enable excimer

ARG IMAGICK_VERSION=3.7.0
# Imagick is installed from the archive because regular installation fails
# See: https://github.com/Imagick/imagick/issues/643#issuecomment-1834361716
RUN curl -L -o /tmp/imagick.tar.gz https://github.com/Imagick/imagick/archive/refs/tags/${IMAGICK_VERSION}.tar.gz \
    && tar --strip-components=1 -xf /tmp/imagick.tar.gz \
    && phpize && ./configure && make && make install \
    && echo "extension=imagick.so" > /usr/local/etc/php/conf.d/docker-php-ext-imagick.ini \
    && rm -rf /tmp/*

RUN docker-php-ext-configure intl && \
    docker-php-ext-install exif gd zip mysqli opcache intl

RUN apk del -f .build-deps $PHPIZE_DEPS

RUN echo "opcache.jit_buffer_size=500000000" >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

# Install wp-cli
RUN curl -o /usr/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/bin/wp

RUN { \
        echo 'error_reporting = E_ALL'; \
        echo 'display_errors = Off'; \
        echo 'display_startup_errors = Off'; \
        echo 'log_errors = On'; \
        echo 'error_log = /dev/stderr'; \
        echo 'log_errors_max_len = 1024'; \
        echo 'ignore_repeated_errors = On'; \
        echo 'ignore_repeated_source = Off'; \
        echo 'html_errors = Off'; \
        echo 'catch_workers_output = yes'; \
        echo 'decorate_workers_output = no'; \
    } > /usr/local/etc/php/conf.d/error-logging.ini
