#!/bin/bash
NEXTCLOUD_DIR=/var/www/nextcloud
COMMAND="sudo -u nextcloud php ${NEXTCLOUD_DIR}/occ "

$COMMAND status
yunohost service restart php7.0-fpm 
$COMMAND app:enable qownnotesapi
