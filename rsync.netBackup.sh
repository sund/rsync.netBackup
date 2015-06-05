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

rsyncKey() {
# rsync up with specific key
    echo =============================================================
    echo -e "Start rsync to \n$remoteServer:$remoteDest\nwith specific key\n"
    rsync -Cavz --delete-after -e "ssh -i $sshKeyPath -p$remotePort" $gitRakeBackups/ $remoteUser@$remoteServer:$remoteDest
}

sshQuotaKey() {
#quota check: with a key remoteServer, run the quota command
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
else
  echo -n "config supplied valid ssh key "
  echo $rsyncSSHKEY
fi

if [ -z "$rsyncUSER" ]; then echo "rsyncUSER is unset"; else echo "rsyncUSER is set to '$rsyncUSER'"; fi
if [ -z "$rsyncSERVER" ]; then echo "rsyncSERVER is unset"; else echo "rsyncSERVER is set to '$rsyncSERVER'"; fi
if [ -z "$rsyncSSHKEY" ]; then echo "rsyncSSHKEY is unset"; else echo "rsyncSSHKEY is set to '$rsyncSSHKEY'"; fi

# check account creds
if [ -z "$rsyncUSER" ] && [ -z "$rsyncSERVER" ] && [ -e $rsyncSSHKEY -a -r $rsyncSSHKEY ]
  then
  rsyncConnection
else
  echo "Error connecting to $rsyncUSER@$rsyncSERVER."
  echo "See https://github.com/sund/rsync.netBackup/wiki/Configuration"
  exit 1
fi

# what type/kind of host are we on
determineOS

# Print version
printScriptver

###
## Exit gracefully
#
exit 0
