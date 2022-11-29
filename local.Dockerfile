FROM composer:2.4.4 as vendor
WORKDIR /app
COPY composer.json composer.json
COPY composer.lock composer.lock
RUN composer install \
    --ignore-platform-reqs \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist \
    --quiet

FROM php:8.1.12-apache
RUN apt update \
    && apt upgrade -y \
    && apt install -y libpq-dev
RUN docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql
# setting PHP conf
# XDebug
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug
# copy Apache virtual host
COPY ./000-default.conf /etc/apache2/sites-available/000-default.conf
# Use the PORT environment variable in Apache configuration files.
# https://cloud.google.com/run/docs/reference/container-contract#port
ENV PORT=80
RUN sed -i 's/80/${PORT}/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf
# enabling Apache mod rewrite
RUN a2enmod rewrite
# create system user ("example_user" with uid 1000)
RUN useradd -G www-data,root -u 1000 -d /home/example_user example_user
RUN mkdir /home/example_user && \
    chown -R example_user:example_user /home/example_user
# copy application with existing permissions
COPY --chown=example_user:example_user ./ /var/www/html
WORKDIR /var/www/html
RUN mkdir vendor
COPY --from=vendor /app/vendor/ vendor
# shared PHP conf
RUN mv /var/www/html/shared.ini /usr/local/etc/php/conf.d/shared.ini
# dev PHP conf
RUN mv /var/www/html/dev.ini /usr/local/etc/php/conf.d/dev.ini
# expose and run servers on port
# running Apache
CMD apache2-foreground