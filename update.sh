#!/bin/bash

MC_HOME=/opt/minecraft/server
MC_BACKUP_GAMES_FOLDER=/opt/minecraft/backup_games-$(date +%F)
mkdir -p /tmp/mc/
echo "Getting latest release"
MC_VERSION_LINK=$(node index.js release)
MC_VERSION=$(echo $MC_VERSION_LINK | cut -d" " -f1)
MC_LINK=$(echo $MC_VERSION_LINK | cut -d" " -f2)

echo "Latest release is version: $MV_VERSION"

echo "Downloading last server.jar"
wget --quiet $MC_LINK -O /tmp/mc/server-$MC_VERSION.jar


# backup games
# Backup current games folders
GAMES_FOLDERS=$(cd $MC_HOME && ls -d */ | grep -v logs | grep -v crash-reports | grep -v latest-game)
echo "GAMES_FOLDERS: $GAMES_FOLDERS"
mkdir -pv $MC_BACKUP_GAMES_FOLDER

for folder in $GAMES_FOLDER; do
    cp -vr $folder $MC_BACKUP_GAMES_FOLDER
done


CK_NEWSERVER=$(cksum /tmp/mc/server-$MC_VERSION.jar | cut -d' ' -f1,2)
CK_OLDSERVER=$(cksum $MC_HOME/server.jar | cut -d' ' -f1,2)
echo "CK_NEWSERVER: $CK_NEWSERVER"
echo "CK_OLDSERVER: $CK_OLDSERVER"

if [ "$CK_NEWSERVER" = "$CK_OLDSERVER" ]; then
    echo "************* Nothing to do, already latest release"
else
    echo "************* updating server"
    # kill actual server
    screen -X stuff 'stop^M'
    sleep 10
    # update server
    unlink $MC_HOME/server.jar
    cp -v /tmp/mc/server-$MC_VERSION_LINK.jar $MC_HOME/
    ln -s $MC_HOME/server-$MC_VERSION_LINK.jar $MC_HOME/server.jar
    # relaunch server
    screen -X stuff './launch_minecraft_server.sh latest-game'
fi

