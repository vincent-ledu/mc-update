#!/bin/bash

MC_HOME=/opt/minecraft/server

screen -X stuff 'say Backup Time!^M'

screen -X stuff 'save-off^M'
screen -X stuff 'save-all^M'

sleep 30

CUR_VERSION=$(cat $MC_HOME/version.txt)
MC_BACKUP_GAMES_FOLDER=/opt/minecraft/backup_games/$(date +%Y-%m-%d_%H%M%S)-$CUR_VERSION
GAMES_FOLDERS=$(cd $MC_HOME && ls -d */ | grep -v logs | grep -v crash-reports | grep -v latest-game)
echo "GAMES_FOLDERS: $GAMES_FOLDERS"
mkdir -pv $MC_BACKUP_GAMES_FOLDER

for folder in $GAMES_FOLDERS; do
    cp -r $MC_HOME/$folder $MC_BACKUP_GAMES_FOLDER
done
tar cvzf $MC_BACKUP_GAMES_FOLDER.tgz $MC_BACKUP_GAMES_FOLDER && rm -rf $MC_BACKUP_GAMES_FOLDER

screen -X stuff 'save-on^M'
screen -X stuff 'say Backup is done!^M'

find /opt/minecraft/backup_games/ -type f -mtime +7 -exec rm -f {} \;