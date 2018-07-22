#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi




Bind_Address="10.10.10.10"
PASSWORD="PASS"



# Install & Configure MYSQL

sudo debconf-set-selections <<< "mariadb-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mariadb-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mariadb-server python-pymysql

sudo touch /etc/mysql/mariadb.conf.d/99-overcloud.cnf

echo "[mysqld]" >> /etc/mysql/mariadb.conf.d/99-overcloud.cnf
echo "bind-address = $Bind_Address" >> /etc/mysql/mariadb.conf.d/99-overcloud.cnf
echo "default-storage-engine = innodb" >> /etc/mysql/mariadb.conf.d/99-overcloud.cnf
echo "innodb_file_per_table = on" >> /etc/mysql/mariadb.conf.d/99-overcloud.cnf
echo "max_connections  = 4096" >> /etc/mysql/mariadb.conf.d/99-overcloud.cnf
echo "collation-server = utf8_general_ci" >> /etc/mysql/mariadb.conf.d/99-overcloud.cnf
echo "character-set-server = utf8" >> /etc/mysql/mariadb.conf.d/99-overcloud.cnf

service mysql restart

echo -e "$PASSWORD\nn\ny\ny\ny\ny" | mysql_secure_installation

