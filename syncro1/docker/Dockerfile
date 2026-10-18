FROM composer:2 AS composer

FROM php:8.3-fpm-bookworm

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip libicu-dev libzip-dev libpng-dev libjpeg62-turbo-dev libfreetype6-dev libxml2-dev libonig-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" mysqli mbstring intl gd zip xml opcache \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer /usr/bin/composer /usr/bin/composer
WORKDIR /var/www/mantis
COPY . /var/www/mantis
RUN composer install --no-interaction --no-progress --prefer-dist --optimize-autoloader \
    && mkdir -p /var/lib/syncro1/uploads /var/log/syncro1 \
    && cp syncro1/config/config_inc.php config/config_inc.php \
    && cp syncro1/config/custom_constants_inc.php config/custom_constants_inc.php \
    && cp syncro1/config/custom_strings_inc.php config/custom_strings_inc.php \
    && chmod +x syncro1/scripts/* \
    && chown -R www-data:www-data /var/lib/syncro1 /var/log/syncro1

COPY syncro1/deploy/php.ini.template /usr/local/etc/php/conf.d/zz-syncro1.ini.template
COPY syncro1/deploy/php-fpm-pool.conf /usr/local/etc/php-fpm.d/zz-syncro1.conf
RUN rm -f /usr/local/etc/php-fpm.d/www.conf

COPY syncro1/docker/entrypoint.sh /usr/local/bin/syncro1-entrypoint
RUN chmod 0755 /usr/local/bin/syncro1-entrypoint

ENTRYPOINT ["syncro1-entrypoint"]
CMD ["php-fpm", "-F"]
