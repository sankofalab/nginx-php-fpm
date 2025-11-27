FROM dunglas/frankenphp:latest

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy composer files first for better Docker layer caching
COPY composer.json composer.lock* /app/

# Set working directory
WORKDIR /app

# Install dependencies
RUN composer install --optimize-autoloader --no-interaction

# Copy the rest of the application
COPY . /app

# Expose port
EXPOSE 80

ARG APP_ENV=production
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN install-php-extensions bcmath intl pcntl gd curl pdo_mysql opcache mbstring redis

COPY . /app
COPY --from=vendor /app/vendor /app/vendor

# Copy compiled frontend assets without installing Node/Yarn in this stage
COPY --from=assets /app/public/build /app/public/build

COPY --from=vendor /usr/local/bin/install-php-extensions /usr/local/bin/install-php-extensions
COPY --from=vendor /usr/bin/composer /usr/bin/composer

RUN mkdir -p storage bootstrap/cache;
RUN chown -R www-data:www-data storage bootstrap/cache;
RUN chmod -R 775 storage bootstrap/cache;

#EXPOSE 80
CMD ["php", "artisan", "octane:frankenphp", "--host=0.0.0.0", "--port=80"]

