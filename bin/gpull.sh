#!/bin/bash

master() {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    git checkout master -q && git pull -q
  else
    hg pull && hg checkout "last(public())"
  fi
}


LOCAL=~/Documents/Code/git
for HOSTING in adullact  babolivier  codecommit  enough  framagit  github  gitlab  
do
  cd ${LOCAL}/${HOSTING}
  for DIR in $(ls -1)
  do
    cd ${LOCAL}/${HOSTING}/${DIR}
#    test -d .git && git pull -q
    master
    if [[ ! $? -eq 0 ]]
    then
      echo "####### ${LOCAL}/${HOSTING}/${DIR} à vérifier #######"
    fi
  done
done
