#!/bin/bash

################################
#
# rsync.netBackup.sh
# -----------------------------
#
#
################################

## License goes here
# TBD

###
## Settings/Variables
#

### in cron job, the path may be just /bin and /usr/bin
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
#
OSNAME=`uname -s` #
PDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
confFile="$PDIR/rsync.netBackup.conf"
excludeFile="excludeFiles.txt"

###
## Functions
#

checkSize() {
    echo ===== Sizing =====
    echo
}

rsyncConnection() {
  echo "Testing connection to $rsyncUSER@$rsyncSERVER..."
  ssh $rsyncSERVER -l $rsyncUSER -T ls > /dev/null
}

rsyncUP() {
# rsync up with specific key
    echo =============================================================
    echo -e "Start rsync to \n$rsyncUSER:$rsyncSERVER\n$rsyncSSHKEY"
    echo "rsync -raz --verbose $excludeLIST $sshKeyUsage $localSource/ $rsyncUSER@$rsyncSERVER:$remoteDestination/"
    rsync -raz --verbose "$excludeLIST" "$sshKeyUsage" "$localSource/" "$rsyncUSER@$rsyncSERVER:$remoteDestination/"
}

rsyncQuota() {
#quota check
	if [[ $checkQuota == "true" || $checkQuota = 1 ]]
	then
	    echo =============================================================
	    echo -e "Quota check: \n$remoteUser@$remoteServer:$remoteModule\nwith key\n"
		ssh -p $remotePort -i $sshKeyPath $remoteUser@$remoteServer "quota"
	    echo =============================================================

	fi
}

printScriptver() {
	# print the most recent tag
  echo =============================================================
	echo "This is $0"
  version=$(git describe --abbrev=0 --tags 2>/dev/null)
  if [ $? -eq 0 ]
    then
    echo "Version $version, commit #$(git log --pretty=format:'%h' -n 1)."
  fi
}

determineOS() {
case "$OSNAME" in
    "Linux")
        ;;
    "Darwin")
        ;;
    "SunOS")
        ;;
    *)
        ;;
esac
}

printVars() {
  echo =============================================================
  echo          ============== Variables ================
  echo "conf file -->" $confFile
  echo "remote dest -->" $remoteDestination
  echo "local source -->" $localSource
  echo "exclude files -->" $excludeLIST
  if [ -z "$rsyncUSER" ]; then echo "rsyncUSER is unset"; else echo "rsyncUSER is set to '$rsyncUSER'"; fi
  if [ -z "$rsyncSERVER" ]; then echo "rsyncSERVER is unset"; else echo "rsyncSERVER is set to '$rsyncSERVER'"; fi
  if [ -z "$rsyncSSHKEY" ]; then echo "rsyncSSHKEY is unset"; else echo "rsyncSSHKEY is set to '$rsyncSSHKEY'"; fi
  echo =============================================================
}

timeTrap() {
  trap times EXIT
}

###
## Git'r done
#

# read the conffile
if [ -e $confFile -a -r $confFile ]
then
	source $confFile
	echo "Parsing config file..."
else
	echo "No config file found; Please create a config file."
  echo "See https://github.com/sund/rsync.netBackup/wiki/Configuration"
  exit 1
fi

if [[ -z "$rsyncSSHKEY" ]] # if var is NOT empty
then
  echo "using default key"
  export sshKeyUsage=""
else
  echo -n "config supplied valid ssh key "
  echo $rsyncSSHKEY
  export sshKeyUsage="-e ssh -i $sshKeyPath"
fi

#check account creds
if [ -n "${rsyncUSER}" ] && [ -n "${rsyncSERVER}" ]
  then
  rsyncConnection
else
  echo "Error connecting to $rsyncUSER@$rsyncSERVER."
  echo "See https://github.com/sund/rsync.netBackup/wiki/Configuration"
  exit 1
fi

## for debugging purposes
#printVars

# what type/kind of host are we on
#determineOS

#Rsync it up. fixing issues with local files also synced.
#rsync -raz --verbose /Users/sund/Desktop/FOO/  8326@usw-s008.rsync.net:Backups/FOO/
echo rsync -raz --verbose  --exclude-from=$excludeFile $localSource/ "$rsyncUSER"@"$rsyncSERVER":"$remoteDestination"
rsync -raz --verbose  --exclude-from=$excludeFile $localSource/ "$rsyncUSER"@"$rsyncSERVER":"$remoteDestination"

# size it
rsyncQuota

# Print version
printScriptver

###
## Exit gracefully
#
## for debugging purposes
#timeTrap

exit 0
