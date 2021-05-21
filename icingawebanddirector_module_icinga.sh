#!/bin/sh

apt-get install icingaweb2 libapache2-mod-php
icingacli setup token create

##mysql icingaweb database
mysql -u root -pmy_password -e "CREATE DATABASE icingaweb2;CREATE USER icingaweb2@localhost IDENTIFIED BY '###PASSWORD###';GRANT ALL ON icingaweb2.* TO icingaweb2@localhost;Flush privileges;quit"


##mysql director database
mysql -u root -pmy_password -e "CREATE DATABASE director CHARACTER SET 'utf8';CREATE USER director@localhost IDENTIFIED BY 'some-password';GRANT ALL ON director.* TO director@localhost;"

ICINGAWEB_MODULEPATH="/usr/share/icingaweb2/modules"
REPO_URL="https://github.com/icinga/icingaweb2-module-director"
TARGET_DIR="${ICINGAWEB_MODULEPATH}/director"
MODULE_VERSION="1.8.0"
git clone "${REPO_URL}" "${TARGET_DIR}" --branch v${MODULE_VERSION}

icingacli module enable director
