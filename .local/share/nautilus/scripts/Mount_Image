#!/bin/bash
#
# NAME:		Image Mounting Script
# AUTHOR:	Magnus Anderson <anderson@sonic2000.org>
# LICENSE:	GPL (http://www.gnu.org/licenses/gpl.html)
# REQUIRES:	cdemu, zenity, gnomesu
# VERSION:	1.1
# DESCRIPTION:	A script that will mount ISO, CUE and NRG files with ease.
#		It will use cdemu to mount cue/bin files.
#		Gnomesu is used to make sure users are able to mount images even tough we have no fstab entry
# CHANGELOG:	1.1: My system for checking for a valid extention for the file was not working as it should
# ----------------

# Configure Section
# ----------------

# Mount Path to use (ie, /mnt/ISO)
MOUNT_PATH="/mnt/ISO"

# Configure Section End
# ----------------
CD_IMAGE=$1
CD_IMAGE_EXT=`echo ${CD_IMAGE##*.} | tr A-Z a-z`
STOP=FALSE

if [ ${CD_IMAGE_EXT} == "cue" ]; then
 STOP=FALSE
elif [ ${CD_IMAGE_EXT} == "nrg" ]; then
 STOP=FALSE
elif [ ${CD_IMAGE_EXT} == "iso" ]; then
 STOP=FALSE
else
 STOP=TRUE
fi

if [ ${STOP} == "TRUE" ]; then
 zenity --error --title "Error" --text "$STOP : Filetype \"${CD_IMAGE_EXT}\" can not be mounted with this script. ISO, NRG and CUE files are supported"; 
 exit;
fi


# If the directory $MOUNT_PATH does not exists we need to tell the user that
if [ ! -d $MOUNT_PATH ]; then
 zenity --error --title "Error" --text "$MOUNT_PATH does not exists, please create it and run the script again";
 exit;
fi;

MOUNT_SIZE=0

if [ ${CD_IMAGE_EXT} == "iso" ]; then
 while [ "$MOUNT_SIZE" -eq 0 ]; do
  gnomesu -t "Image Mount (ISO)" -c "umount $MOUNT_PATH; mount -o ro,loop \"$CD_IMAGE\" $MOUNT_PATH";
  MOUNT_SIZE=`ls -l $MOUNT_PATH | grep total | awk '{print $2}'`; sleep 2;
 done
fi

if [ ${CD_IMAGE_EXT} == "nrg" ]; then
 while [ "$MOUNT_SIZE" -eq 0 ]; do
  gnomesu -t "Image Mount (Nero Image)" -c "umount $MOUNT_PATH; mount -o ro,offset=307200,loop \"$CD_IMAGE\" $MOUNT_PATH";
  MOUNT_SIZE=`ls -l $MOUNT_PATH | grep total | awk '{print $2}'`; sleep 2;
 done
fi

if [ ${CD_IMAGE_EXT} == "cue" ]; then
 while [ "$MOUNT_SIZE" -eq 0 ]; do
  gnomesu -t "Image Mount (Binary)" -c "cdemu -u 0; cdemu 0 \"$CD_IMAGE\"; umount $MOUNT_PATH; mount -t iso9660 /dev/cdemu0 $MOUNT_PATH";
  MOUNT_SIZE=`ls -l $MOUNT_PATH | grep total | awk '{print $2}'`; sleep 2;
 done
fi
