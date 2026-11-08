#!/bin/bash
set -e
IP=${1:?Uso: sudo bash n.sh IP_DE_LA_VM}
V=8.8.0
apt update
apt install -y apache2 mariadb-server unzip curl wget php libapache2-mod-php php-cli php-mysql php-curl php-gd php-intl php-mbstring php-xml php-zip php-bcmath php-soap php-ldap php-opcache
PV=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
printf "memory_limit=256M\nupload_max_filesize=20M\npost_max_size=20M\nmax_execution_time=300\n" > /etc/php/$PV/apache2/conf.d/99-suitecrm.ini
cp /etc/php/$PV/apache2/conf.d/99-suitecrm.ini /etc/php/$PV/cli/conf.d/
mysql -e "CREATE DATABASE IF NOT EXISTS suitecrm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; CREATE USER IF NOT EXISTS 'suitecrm'@'localhost' IDENTIFIED BY 'Suite_Pass_2026'; GRANT ALL ON suitecrm.* TO 'suitecrm'@'localhost'; FLUSH PRIVILEGES;"
cd /tmp
wget -q https://github.com/SuiteCRM/SuiteCRM-Core/releases/download/v$V/SuiteCRM-$V.zip
mkdir -p /var/www/suitecrm
unzip -qo SuiteCRM-$V.zip -d /var/www/suitecrm
cd /var/www/suitecrm
chown -R www-data:www-data .
find . -type d -exec chmod 755 {} +
find . -type f -exec chmod 644 {} +
chmod +x bin/console
cat > /etc/apache2/sites-available/suitecrm.conf <<'EOF'
<VirtualHost *:80>
    DocumentRoot /var/www/suitecrm/public
    <Directory /var/www/suitecrm/public>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
a2enmod rewrite
a2dissite 000-default.conf || true
a2ensite suitecrm.conf
systemctl restart apache2
sudo -u www-data php bin/console suitecrm:app:install -u "admin" -p "Admin_2026!" -U "suitecrm" -P "Suite_Pass_2026" -H "localhost" -N "suitecrm" -S "http://$IP" -d "no"
echo "* * * * * cd /var/www/suitecrm; php bin/console schedulers:run" | crontab -u www-data -
curl -I http://localhost