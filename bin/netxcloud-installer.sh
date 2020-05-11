#!/bin/bash
NEXTCLOUD_DIR=/var/www/nextcloud
COMMAND="sudo -u nextcloud php ${NEXTCLOUD_DIR}/occ "

$COMMAND status
yunohost service restart php7.0-fpm 
yunohost service restart nginx

for app in activity bookmarks calendar checksum comments contacts \
  dav deck drawio federatedfilesharing federation \
  files_automatedtagging files_external files_markdown \
  files_pdfviewer files_reader files_rightclick files_sharing \
  files_texteditor files_trashbin files_versions files_videoplayer \
  gallery issuetemplate logreader lookup_server_connector mail music \
  notifications oauth2 ocsms password_policy phonetrack provisioning_api \
  qownnotesapi serverinfo sharebymail survey_client systemtags \
  theming twofactor_backupcodes updatenotification workflowengine
do
  $COMMAND app:enable ${app}
done

