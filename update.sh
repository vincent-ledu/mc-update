#!/bin/bash
if [ $# -eq 0 ]; then
    # no argument
    RELEASE_TYPE=release
else
    RELEASE_TYPE=$1
fi
MC_HOME=/opt/minecraft/server

# Download latest release or snapshot
function downloadLatestRelease() {
    mkdir -p /tmp/mc/
    echo "Getting latest release"
    MC_VERSION_LINK=$(node index.js $RELEASE_TYPE)
    MC_VERSION=$(echo $MC_VERSION_LINK | cut -d" " -f1)
    MC_LINK=$(echo $MC_VERSION_LINK | cut -d" " -f2)

    echo "MC_LINK: |$MC_LINK|"
    echo "MC_VERSION: |$MC_VERSION|"

    echo "Latest release is version: $MC_VERSION"

    echo "Downloading last server.jar"
    wget --quiet $MC_LINK -O /tmp/mc/server-$MC_VERSION.jar
}

# kill actual server
function stopServer() {
    echo "Stopping server then wait 30 secondes"
    screen -X stuff 'stop^M'
    sleep 30
}

function backupGames() {
    # backup games
    # Backup current games folders
    CUR_VERSION=$(cat $MC_HOME/version.txt)
    MC_BACKUP_GAMES_FOLDER=/opt/minecraft/backup_games/$(date +%Y-%m-%d_%H%M%S)-$CUR_VERSION
    GAMES_FOLDERS=$(cd $MC_HOME && ls -d */ | grep -v logs | grep -v crash-reports | grep -v latest-game)
    echo "GAMES_FOLDERS: $GAMES_FOLDERS"
    mkdir -pv $MC_BACKUP_GAMES_FOLDER

    for folder in $GAMES_FOLDERS; do
        cp -r $MC_HOME/$folder $MC_BACKUP_GAMES_FOLDER
    done
    tar cvzf $MC_BACKUP_GAMES_FOLDER.tgz $MC_BACKUP_GAMES_FOLDER && rm -rf $MC_BACKUP_GAMES_FOLDER

}

function updateServer() {
    CK_NEWSERVER=$(cksum /tmp/mc/server-$MC_VERSION.jar | cut -d' ' -f1,2)
    CK_OLDSERVER=$(cksum $MC_HOME/server.jar | cut -d' ' -f1,2)
    echo "CK_NEWSERVER: $CK_NEWSERVER"
    echo "CK_OLDSERVER: $CK_OLDSERVER"

    if [ "$CK_NEWSERVER" = "$CK_OLDSERVER" ]; then
        echo "************* Nothing to do, already latest release"
    else
        echo "************* updating server"
        CUR_VERSION=$(cat $MC_HOME/version.txt)
        # update server
        unlink $MC_HOME/server.jar
        cp -v /tmp/mc/server-$MC_VERSION.jar $MC_HOME/
        ln -s $MC_HOME/server-$MC_VERSION.jar $MC_HOME/server.jar
        echo $MC_VERSION > $MC_HOME/version.txt
    fi
    rm -rf /tmp/mc
}

function launchServer() {
    # relaunch server
    echo "Relaunch server"
    screen -X stuff './launch_minecraft_server.sh latest-game^M'
}

downloadLatestRelease
stopServer
backupGames
updateServer
launchServer