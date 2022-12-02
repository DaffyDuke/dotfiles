#!/bin/bash

# 1.6.3
version=$1

cd ~/Dropbox/Softwares/Linux/
wget https://proton.me/download/bridge/protonmail-bridge_${version}-1_amd64.deb
sudo dpkg -i protonmail-bridge_${version}-1_amd64.deb
if [ $? -eq 0 ]
then
  ls protonmail-bridge_* | grep -v ${version} | xargs rm -v
fi
