#!/bin/zsh
source ~/.zshrc

master() {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    git pull origin -q "$(git_current_branch)"
  else
    hg pull && hg checkout "last(public())"
  fi
}


LOCAL=~/Documents/Code/git
for HOSTING in adullact  babolivier  enough  framagit  github  gitlab  
do
  cd ${LOCAL}/${HOSTING} || exit
  for DIR in $(ls -1 | grep -Ev 'youtube-dl_BEFORE_DMCA_|workspace' )
  do
    cd ${LOCAL}/${HOSTING}/${DIR} || exit
#    test -d .git && git pull -q
    master
    if [[ ! $? -eq 0 ]]
    then
      echo "####### ${LOCAL}/${HOSTING}/${DIR} à vérifier #######"
    fi
  done
done
