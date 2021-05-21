#!/bin/sh

##update and add repos
apt-get -y update
apt-get -y install apt-transport-https wget gnupg
wget -O - https://packages.icinga.com/icinga.key | apt-key add -
. /etc/os-release; if [ ! -z ${UBUNTU_CODENAME+x} ]; then DIST="${UBUNTU_CODENAME}"; else DIST="$(lsb_release -c| awk '{print $2}')"; fi;
echo "deb https://packages.icinga.com/ubuntu icinga-${DIST} main" > /etc/apt/sources.list.d/${DIST}-icinga.list
echo "deb-src https://packages.icinga.com/ubuntu icinga-${DIST} main" >> /etc/apt/sources.list.d/${DIST}-icinga.list

##install icinga2
apt-get -y update
apt-get -y install icinga2
apt-get -y install monitoring-plugins
systemctl restart icinga2
systemctl enable icinga2

##installing highlighting for icinga2
apt-get -y install vim-icinga2 vim-addon-manager
vim-addon-manager -w -y install icinga2

##installing db for backend
apt -y install mariadb-server

##database configuration
##add here the prompting answers
mysql_root_pass=$(date +%s |  base64 | head -c 32)
echo "Mysql root password is $mysql_root_pass \n" > /home/passwords.txt
printf "\ny\n$mysql_root_pass\n$mysql_root_pass\ny\ny\ny\ny\n" | mysql_secure_installation


apt-get -y install icinga2-ido-mysql
mysql_icinga_ido_pass=$(date +%s |  base64 | head -c 32)
echo "Mysql password for icinga user is $mysql_icinga_ido_pass \n" >> /home/passwords.txt
mysql -u root -p@mysql_root_pass -e "CREATE DATABASE icinga;CREATE USER 'icinga'@'localhost' IDENTIFIED BY '@mysql_icinga_ido_pass' ;GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON icinga.* TO 'icinga'@'localhost';quit;"


mysql -u root -p@mysql_root_pass icinga < /usr/share/icinga2-ido-mysql/schema/mysql.sql
icinga2 feature enable ido-mysql
systemctl restart icinga2
