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
apt-get -y install icinga2 monitoring-plugins
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
#mysql_icinga_ido_pass=$(date +%s |  base64 | head -c 32)
#echo "Mysql password for icinga user is $mysql_icinga_ido_pass \n" >> /home/passwords.txt
#mysql -u root -p$mysql_root_pass -e "CREATE DATABASE icinga;CREATE USER 'icinga'@'localhost' IDENTIFIED BY '$mysql_icinga_ido_pass'; GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, INDEX, EXECUTE ON icinga.* TO 'icinga'@'localhost';Flush privileges;quit;"


#mysql -u root -p$mysql_root_pass icinga < /usr/share/icinga2-ido-mysql/schema/mysql.sql
icinga2 feature enable ido-mysql
systemctl restart icinga2


apt-get -y  install icingaweb2 libapache2-mod-php
icingacli setup token create

##mysql icingaweb database
mysql_icingaweb_pass=$(date +%s |  base64 | head -c 32)
echo "Mysql Icingaweb password is $mysql_icingaweb_pass \n" >> /home/passwords.txt
mysql -u root -p$mysql_root_pass -e "CREATE DATABASE icingaweb2;CREATE USER icingaweb2@localhost IDENTIFIED BY '$mysql_icingaweb_pass';GRANT ALL ON icingaweb2.* TO icingaweb2@localhost;Flush privileges;"


##mysql director database
mysql_director_pass=$(date +%s |  base64 | head -c 32)
echo "Mysql director password is $mysql_director_pass \n" >> /home/passwords.txt
mysql -u root -p$mysql_root_pass -e "CREATE DATABASE director CHARACTER SET 'utf8';CREATE USER director@localhost IDENTIFIED BY '$mysql_director_pass';GRANT ALL ON director.* TO director@localhost;Flush privileges;"

##module reactbundle
REACTBUNDLE_MODULE_NAME=reactbundle
REACTBUNDLE_MODULE_VERSION=v0.9.0
REACTBUNDLE_REPO="https://github.com/Icinga/icingaweb2-module-${REACTBUNDLE_MODULE_NAME}"
MODULES_PATH="/usr/share/icingaweb2/modules"
git config --global advice.detachedHead false
git clone ${REACTBUNDLE_REPO} "${MODULES_PATH}/${REACTBUNDLE_MODULE_NAME}" --branch "${REACTBUNDLE_MODULE_VERSION}"
icingacli module enable "${REACTBUNDLE_MODULE_NAME}"

##module ipl
IPL_MODULE_NAME=ipl
IPL_MODULE_VERSION=v0.5.0
IPL_REPO="https://github.com/Icinga/icingaweb2-module-${IPL_MODULE_NAME}"
MODULES_PATH="/usr/share/icingaweb2/modules"
git clone ${IPL_REPO} "${MODULES_PATH}/${IPL_MODULE_NAME}" --branch "${IPL_MODULE_VERSION}"
icingacli module enable "${IPL_MODULE_NAME}"

##module incubator
INCUBATOR_MODULE_NAME=incubator
INCUBATOR_MODULE_VERSION=v0.6.0
INCUBATOR_REPO="https://github.com/Icinga/icingaweb2-module-${INCUBATOR_MODULE_NAME}"
MODULES_PATH="/usr/share/icingaweb2/modules"
git clone ${INCUBATOR_REPO} "${MODULES_PATH}/${INCUBATOR_MODULE_NAME}" --branch "${INCUBATOR_MODULE_VERSION}"
icingacli module enable "${INCUBATOR_MODULE_NAME}"

##icinga director module

ICINGAWEB_MODULEPATH="/usr/share/icingaweb2/modules"
REPO_URL="https://github.com/icinga/icingaweb2-module-director"
TARGET_DIR="${ICINGAWEB_MODULEPATH}/director"
MODULE_VERSION="1.8.0"
git clone "${REPO_URL}" "${TARGET_DIR}" --branch v${MODULE_VERSION}
icingacli module enable director

##Enable business processmodule
BS_PROCESS_ICINGAWEB_MODULEPATH="/usr/share/icingaweb2/modules"
BS_PROCESS_REPO_URL="https://github.com/Icinga/icingaweb2-module-businessprocess"
BS_PROCESS_TARGET_DIR="${ICINGAWEB_MODULEPATH}/businessprocess"
git clone "${BS_PROCESS_REPO_URL}" "${BS_PROCESS_TARGET_DIR}"

icingacli module enable businessprocess

##changing the permission to the relevent owners
chown -R www-data:icingaweb2 /etc/icingaweb2/

##running api setup
sudo icinga2 api setup

##adding an api user for icingaweb
printf "object ApiUser \"icingaweb2\" {\n  password = \"Wijsn8Z9eRs5E25d\"\n  permissions = [ \"status/query\", \"actions/*\", \"objects/modify/*\", \"objects/query/*\" ]\n}\n" >> /etc/icinga2/conf.d/api-users.conf

##adding an api user for director instead of using root
director_api_user_password=$(date +%s |  base64 | head -c 32)
echo "object ApiUser \"director\" {\n  password = \"$director_api_user_password\"\n  permissions = [ \"*\" ]\n}\n" >> /etc/icinga2/conf.d/api-users.conf

usermod -a -G icingaweb2 www-data;
##director demon

useradd -r -g icingaweb2 -d /var/lib/icingadirector -s /bin/false icingadirector
install -d -o icingadirector -g icingaweb2 -m 0750 /var/lib/icingadirector
MODULE_PATH=/usr/share/icingaweb2/modules/director
cp "${MODULE_PATH}/contrib/systemd/icinga-director.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable icinga-director.service
systemctl start icinga-director.service


