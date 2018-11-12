#!/bin/bash

source /etc/yunohost/personnals
today=`date +'%y%m%d'`
cd /var/backups

Web()
{
  tar cvfzp /var/backups/web.tar.gz /var/www
}

Mails()
{
#  tar cvfzp /var/backups/mail.tar.gz /var/mail
  output=/home/yunohost.backup/mails
  mkdir -p ${output}
  cd ${output}
  rm -rvf ${output}/*
  /root/imapsave --ssl --port ${port} --password ${password} ${server} ${user}
  bzip2 -9 *
  mkdir $today
  mv *bz2 $today/
  ln -sf $today today
}

Importants()
{
  tar cvfzp /var/backups/bigfiles.tar.gz /root /etc /home/vmail/fetchcmdvmail
}

Databases()
{
  PASS=`cat /etc/yunohost/mysql`
  mysql --user=root --password=$PASS  -N -e 'show databases' | while read dbname; do mysqldump --user=root --password=$PASS --complete-insert --routines --triggers --single-transaction "$dbname" > "$dbname".sql; [[ $? -eq 0 ]]&& gzip -f "$dbname".sql; done
}

yunohost()
{
  BKPMNTPOINT="/home/yunohost.backup"
  BKPPREFIX=“bkpmove-”
  OCC=“sudo -u nextcloud /usr/bin/php /var/www/nextcloud/occ”
  
  ${OCC} trashbin:expire
  ${OCC} trashbin:cleanup
  ${OCC} maintenance:mode --on
  rsync -avz --partial --progress --delete-before /home/yunohost.app/nextcloud /home/yunohost.backup/nextcloud
  ${OCC} maintenance:mode --off
#  mkdir ${BKPMNTPOINT}/archives 2>/dev/null
#  for i in $(yunohost backup list |tail -n +2|cut -d " " -f 4|grep ${BKPPREFIX})
#  do
#    echo Suppression du backup $i
#    yunohost backup delete $i
#  done
#  yunohost backup create -n ${BKPPREFIX}$(date ‘+%Y%m%d_%H’) -o ${BKPMNTPOINT}/archives --system
#  BACKUP_CORE_ONLY=1 yunohost backup create --apps nextcloud
  yunohost backup create --apps $(yunohost app list -i | grep -v nextcloud |grep id: | tr -d '\012' | sed -e "s+id:++g" )
  yunohost backup create --system
}

PushToOVH()
{
  mount -t nfs ${FTPBACKUPHOST}:/export/ftpbackup/${FTPUSER} /tmp/nfs
  rsync -avz --progress --size-only /var/backups/* /tmp/nfs/
  rsync -avz --progress --size-only /home/yunohost.backup/archives/* /tmp/nfs/
  rsync -avz --progress --size-only /home/yunohost.backup/mails /tmp/nfs/mails
  umount /tmp/nfs
}

Web
Mails
Importants
Databases
yunohost
PushToOVH
