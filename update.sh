#!/bin/bash
if [ $# -eq 0 ]; then
    # no argument
    RELEASE_TYPE=release
else
    RELEASE_TYPE=$1
fi
MC_HOME=/opt/minecraft/server
CUR_VERSION=$(cat $MC_HOME/version.txt || die "$MC_HOME/version.txt not found")

# error handling
function die() {
    echo "Error: $1"
    exit 1
}

# Download latest release or snapshot
function downloadLatestRelease() {
    mkdir -p /tmp/mc/ || die "cannot create /tmp/mc"
    echo "Getting latest release"
    MC_VERSION_LINK=$(node ~/mc-update/index.js $RELEASE_TYPE || die "Cannot get Minecraft Version")
    MC_VERSION=$(echo $MC_VERSION_LINK | cut -d" " -f1)
    MC_LINK=$(echo $MC_VERSION_LINK | cut -d" " -f2)

    echo "MC_LINK: |$MC_LINK|"
    echo "MC_VERSION: |$MC_VERSION|"
    if [ "$MC_VERSION" = "$CUR_VERSION" ]; then
        echo "Server is already latest $RELEASE_TYPE. Exiting."
        exit 0
    fi

    echo "Latest release is version: $MC_VERSION"
    

    echo "Downloading last server.jar"
    wget --quiet $MC_LINK -O /tmp/mc/server-$MC_VERSION.jar || die "Cannot download $MC_LINK to /tmp/mc/server-$MC_VERSION.jar"
}

function isMinecraftLaunched() {
    ps -ef | grep "/opt/minecraft/server/server.jar" | grep -v "grep"
    return $?
}

# kill actual server
function stopServer() {
    echo "Stopping server then wait 30 secondes"
    isMinecraftLaunched && screen -ls && screen -X stuff 'stop^M' && sleep 30
}

function backupGames() {
    # backup games
    # Backup current games folders
    MC_BACKUP_FOLDER_BASE=/opt/minecraft/backup_games
    MC_BACKUP_GAMES_FOLDER=$(date +%Y-%m-%d_%H%M%S)-$CUR_VERSION
    GAMES_FOLDERS=$(cd $MC_HOME && ls -d */ | grep -v logs | grep -v crash-reports | grep -v latest-game)
    echo "GAMES_FOLDERS: $GAMES_FOLDERS"
    mkdir -pv $MC_BACKUP_FOLDER_BASE/$MC_BACKUP_GAMES_FOLDER

    for folder in $GAMES_FOLDERS; do
        cp -r $MC_HOME/$folder $MC_BACKUP_FOLDER_BASE/$MC_BACKUP_GAMES_FOLDER || die "Error while copying $MC_HOME/$folder $MC_BACKUP_FOLDER_BASE/$MC_BACKUP_GAMES_FOLDER. Aborting..."
    done
    cd $MC_BACKUP_FOLDER_BASE && tar cvzf $MC_BACKUP_GAMES_FOLDER.tgz $MC_BACKUP_GAMES_FOLDER && rm -rf $MC_BACKUP_GAMES_FOLDER

}

function updateServer() {
    CK_NEWSERVER=$(cksum /tmp/mc/server-$MC_VERSION.jar | cut -d' ' -f1,2 || die "cksum /tmp/mc/server-$MC_VERSION.jar failed")
    CK_OLDSERVER=$(cksum $MC_HOME/server.jar | cut -d' ' -f1,2 || die "cksum $MC_HOME/server.jar failed")
    echo "CK_NEWSERVER: $CK_NEWSERVER"
    echo "CK_OLDSERVER: $CK_OLDSERVER"

    if [ "$CK_NEWSERVER" = "$CK_OLDSERVER" ]; then
        echo "************* Nothing to do, already latest release"
    else
        echo "************* Updating server"
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
    screen -ls && screen -X stuff './launch_minecraft_server.sh latest-game^M' || (screen -dmS minecraft && screen -X stuff "cd $MC_HOME && ./launch_minecraft_server.sh latest-game^M")
}

downloadLatestRelease
stopServer
backupGames
updateServer
launchServer