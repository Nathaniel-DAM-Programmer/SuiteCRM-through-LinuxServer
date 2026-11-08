#!/bin/bash
set -e
IP=${1:?Uso: sudo bash d.sh IP_DE_LA_VM}
apt update
apt install -y docker.io docker-compose-v2
mkdir -p /root/suitecrm-docker
cd /root/suitecrm-docker
cat > Dockerfile <<'EOF'
FROM php:8.3-apache
ARG V=8.8.0
RUN apt-get update && apt-get install -y libzip-dev libpng-dev libjpeg-dev libfreetype6-dev libicu-dev libxml2-dev libldap2-dev libonig-dev libcurl4-openssl-dev unzip curl && docker-php-ext-configure gd --with-freetype --with-jpeg && docker-php-ext-install -j2 gd intl mysqli pdo_mysql zip bcmath soap opcache ldap && a2enmod rewrite
RUN curl -L -o /tmp/s.zip https://github.com/SuiteCRM/SuiteCRM-Core/releases/download/v$V/SuiteCRM-$V.zip && unzip -q /tmp/s.zip -d /var/www/html && rm /tmp/s.zip
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf && sed -ri 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf && sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
RUN printf 'memory_limit=256M\nupload_max_filesize=20M\npost_max_size=20M\n' > /usr/local/etc/php/conf.d/s.ini
RUN chown -R www-data:www-data /var/www/html && chmod +x /var/www/html/bin/console
EOF
cat > docker-compose.yml <<'EOF'
services:
  db:
    image: mariadb:10.11
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: Root_Pass_2026
      MARIADB_DATABASE: suitecrm
      MARIADB_USER: suitecrm
      MARIADB_PASSWORD: Suite_Pass_2026
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    volumes:
      - db_data:/var/lib/mysql
  web:
    build: .
    restart: unless-stopped
    depends_on:
      - db
    ports:
      - "8080:80"
    volumes:
      - suitecrm_data:/var/www/html
volumes:
  db_data:
  suitecrm_data:
EOF
docker compose up -d --build
sleep 40
docker compose exec -u www-data web php bin/console suitecrm:app:install -u "admin" -p "Admin_2026!" -U "suitecrm" -P "Suite_Pass_2026" -H "db" -N "suitecrm" -S "http://$IP:8080" -d "no"
docker compose ps
curl -I http://localhost:8080