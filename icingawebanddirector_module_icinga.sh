#!/bin/sh

apt-get install icingaweb2 libapache2-mod-php
icingacli setup token create

##mysql icingaweb database
mysql_icingaweb_pass=$(date +%s |  base64 | head -c 32)
echo "Mysql Icingaweb password is $mysql_icingaweb_pass \n" >> /home/passwords.txt
mysql -u root -p$mysql_root_pass -e "CREATE DATABASE icingaweb2;CREATE USER icingaweb2@localhost IDENTIFIED BY '$mysql_icingaweb_pass';GRANT ALL ON icingaweb2.* TO icingaweb2@localhost;Flush privileges;quit"


##mysql director database
mysql_director_pass=$(date +%s |  base64 | head -c 32)
echo "Mysql director password is $mysql_director_pass \n" >> /home/passwords.txt
mysql -u root -p$mysql_root_pass -e "CREATE DATABASE director CHARACTER SET 'utf8';CREATE USER director@localhost IDENTIFIED BY '$mysql_director_pass';GRANT ALL ON director.* TO director@localhost;"

ICINGAWEB_MODULEPATH="/usr/share/icingaweb2/modules"
REPO_URL="https://github.com/icinga/icingaweb2-module-director"
TARGET_DIR="${ICINGAWEB_MODULEPATH}/director"
MODULE_VERSION="1.8.0"
git clone "${REPO_URL}" "${TARGET_DIR}" --branch v${MODULE_VERSION}

icingacli module enable director
