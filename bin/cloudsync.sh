#!/bin/bash

OneDriveTechsys()
{
    cd ~/ || exit 1
    for dir in Documents_Clients Documents_associes Documents_internes Echange_Clients
    do
        rclone -v sync OneDriveTechsys:${dir} Local:OneDriveTechsys/${dir}
    done
}

SyncKimsufiToPassport()
{
  rclone -v copy Local:/media/daffy/My\ Passport/Freenas/Backups Dropbox:Freenas/
}

GoogleDrive()
{
    rclone --size-only --drive-acknowledge-abuse --ignore-checksum -v copy GoogleDrive:/ Google\ Drive
}

SyncDropboxNextcloud()
{
    cd ~/ || exit 1
    # DirectoryListing Dropbox
    for service in Dropbox Nextcloud
    do
        rclone lsd ${service}: | awk '{print $NF}' > /tmp/${service}.lst
    done
    # Sync only if source exist in both sides
    # Exclude Photos/Videos/Software directory
    for source in $(diff -u /tmp/Dropbox.lst /tmp/Nextcloud.lst | grep -E "^\s[a-Z]" | grep -v -E 'Photo|Software|Vid')
    do
        rclone -v sync Dropbox:${source}/ Nextcloud:${source}/
    done
}

if [ -x $(which rclone) ]
then
    OneDriveTechsys
    GoogleDrive
    SyncDropboxNextcloud
#   SyncKimsufiToPassport
else
    echo "Please install rclone, "
    echo "then configure it with rclone config"
    exit 1
fi
