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
# Configure PHP for production
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
# https://github.com/docker-library/docs/blob/master/php/README.md#configuration
# configure PHP for Cloud Run
# precompile PHP code with opcache
# the `-j "$(nproc)"` option tells the compiler to execute this recipe in a parallel job
RUN docker-php-ext-install -j "$(nproc)" opcache
# specific ini options for Cloud Run and opcache
RUN set -ex; \
  { \
    echo "; Cloud Run enforces memory & timeouts"; \
    echo "memory_limit = -1"; \
    echo "max_execution_time = 0"; \
    echo "; File upload at Cloud Run network limit"; \
    echo "upload_max_filesize = 32M"; \
    echo "post_max_size = 32M"; \
    echo "; Configure Opcache for Containers"; \
    echo "opcache.enable = On"; \
    echo "opcache.validate_timestamps = Off"; \
    echo "; Configure Opcache Memory (Application-specific)"; \
    echo "opcache.memory_consumption = 32"; \
  } > "$PHP_INI_DIR/conf.d/cloud-run.ini"
# shared PHP conf
RUN mv /var/www/html/shared.ini /usr/local/etc/php/conf.d/shared.ini
# expose and run servers on port
# running Apache
CMD apache2-foreground