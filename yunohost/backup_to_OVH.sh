#!/bin/bash

source /etc/yunohost/personnals

if [[ `ps -ef | grep backup.sh | grep -v grep | wc -l` -ge 1 ]]
then
	echo "backup.sh already running, please wait a few"
	ps -ef | grep backup.sh | grep -v grep
	exit 1
fi

cd /home/yunohost.backup/archives/
for file in *
do
	echo "sending $file ...."
	curl -aT $file ftp://$FTPUSER:$FTPPASS@$FTPBACKUPHOST/
done
cd /var/backups
for file in $(ls -1 | grep -v slap)
do
	echo "sending $file ...."
 	curl -aT $file ftp://$FTPUSER:$FTPPASS@$FTPBACKUPHOST/
done
