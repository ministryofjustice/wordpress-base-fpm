# 26-03-2024
# alpine-3.19 is vulnerable, using alipine3.18
FROM php:8.3-fpm-alpine3.18

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

RUN docker-php-ext-configure intl && \
    docker-php-ext-install -j "$(nproc)" exif gd zip mysqli opcache intl

# Download, patch and install imagick
# https://github.com/docker-library/wordpress/blob/0c3488c5a6623a4858964ba69950260018201d79/latest/php8.3/fpm/Dockerfile#L47
RUN curl -fL -o imagick.tgz 'https://pecl.php.net/get/imagick-3.7.0.tgz'; \
    echo '5a364354109029d224bcbb2e82e15b248be9b641227f45e63425c06531792d3e *imagick.tgz' | sha256sum -c -; \
    tar --extract --directory /tmp --file imagick.tgz imagick-3.7.0; \
    grep '^//#endif$' /tmp/imagick-3.7.0/Imagick.stub.php; \
    test "$(grep -c '^//#endif$' /tmp/imagick-3.7.0/Imagick.stub.php)" = '1'; \
    sed -i -e 's!^//#endif$!#endif!' /tmp/imagick-3.7.0/Imagick.stub.php; \
    grep '^//#endif$' /tmp/imagick-3.7.0/Imagick.stub.php && exit 1 || :; \
    docker-php-ext-install /tmp/imagick-3.7.0; \
    rm -rf imagick.tgz /tmp/imagick-3.7.0;

RUN apk del .build-deps $PHPIZE_DEPS

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
