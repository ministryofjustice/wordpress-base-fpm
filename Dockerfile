FROM php:8.2-fpm-alpine

RUN apk add --update bash  \
    zlib-dev  \
    libpng-dev  \
    libzip-dev  \
    libxml2-dev \
    ghostscript \
    imagemagick \
    imagemagick-libs \
    imagemagick-dev \
    libjpeg-turbo \
    libgomp \
    freetype-dev \
    icu-dev  \
    htop  \
    mariadb-client

RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS

RUN pecl install imagick
RUN docker-php-ext-enable imagick && \
    docker-php-ext-configure intl && \
    docker-php-ext-install -j "$(nproc)" exif gd zip mysqli opcache intl

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
