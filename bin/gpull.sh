#!/bin/bash

LOCAL=~/Documents/Code/git
for HOSTING in adullact  babolivier  codecommit  enough  framagit  github  gitlab  
do
  cd ${LOCAL}/${HOSTING}
  for DIR in $(ls -1)
  do
    cd ${LOCAL}/${HOSTING}/${DIR}
    test -d .git && git pull -q
    if [[ ! $? -eq 0 ]]
    then
      echo "####### ${LOCAL}/${HOSTING}/${DIR} à vérifier #######"
    fi
  done
done
