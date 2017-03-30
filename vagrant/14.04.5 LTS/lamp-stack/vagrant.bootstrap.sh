#!/usr/bin/env bash

# MACHINE SETUP

# Adding multiverse sources.
cat > /etc/apt/sources.list.d/multiverse.list << EOF
deb http://archive.ubuntu.com/ubuntu trusty multiverse
deb http://archive.ubuntu.com/ubuntu trusty-updates multiverse
deb http://security.ubuntu.com/ubuntu trusty-security multiverse
EOF

apt-get update


# APACHE SETUP

# Installing Packages
apt-get install -y apache2 libapache2-mod-fastcgi apache2-mpm-worker

# linking Vagrant directory to Apache 2.4 public directory
rm -rf /var/www
ln -fs /vagrant /var/www

# Add ServerName to httpd.conf
echo "ServerName localhost" > /etc/apache2/httpd.conf
# Setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:80>
  DocumentRoot "/var/www/public"
  ServerName localhost
  <Directory "/var/www/public">
    AllowOverride All
  </Directory>
</VirtualHost>
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /vagrant/tests
    ServerName tests.local
    <Directory /vagrant/tests>
        AllowOverride All
        Options -Indexes +FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-enabled/000-default.conf

# Loading needed modules to make apache work
a2enmod actions fastcgi rewrite
service apache2 reload

# PHP SETUP

# Installing packages
apt-get install -y php5 php5-cli php5-fpm curl php5-curl php5-mcrypt php5-xdebug

# Creating the configurations inside Apache
cat > /etc/apache2/conf-available/php5-fpm.conf << EOF
<IfModule mod_fastcgi.c>
    AddHandler php5-fcgi .php
    Action php5-fcgi /php5-fcgi
    Alias /php5-fcgi /usr/lib/cgi-bin/php5-fcgi
    FastCgiExternalServer /usr/lib/cgi-bin/php5-fcgi -socket /var/run/php5-fpm.sock -pass-header Authorization

    # NOTE: using '/usr/lib/cgi-bin/php5-cgi' here does not work,
    #   it doesn't exist in the filesystem!
    <Directory /usr/lib/cgi-bin>
        Require all granted
    </Directory>

</IfModule>
EOF

# Enabling php modules
php5enmod mcrypt

# Changing php.ini to display all errors
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/fpm/php.ini

# Triggering changes in apache
a2enconf php5-fpm
service apache2 reload

# MYSQL SETUP

# Setting MySQL root user password root/root
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

# Installing packages
apt-get install -y mysql-server mysql-client php5-mysql

# PHPMYADMIN SETUP

# Default PHPMyAdmin Settings
debconf-set-selections <<< 'phpmyadmin phpmyadmin/dbconfig-install boolean true'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/app-password-confirm password root'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/admin-pass password root'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/app-pass password root'
debconf-set-selections <<< 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2'

# Install PHPMyAdmin
apt-get install -y phpmyadmin
ln -s /etc/phpmyadmin/apache.conf /etc/apache2/sites-enabled/phpmyadmin.conf

# Restarting apache to make changes
service apache2 restart

# TOOLS

# Installing GIT
apt-get install -y git

# Install Composer
curl -s https://getcomposer.org/installer | php

# Make Composer available globally
mv composer.phar /usr/local/bin/composer
