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
PDIR=$(dirname $(readlink -f $0))
confFile="$PDIR/auto-gitlab-backup.conf"

###
## Functions
#

checkSize() {
    echo ===== Sizing =====
    echo "Total disk space used for backup storage.."
    echo "Size - Location"
    echo `du -hs "$gitRakeBackups"`
    echo
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
	echo "Version $(git describe --abbrev=0 --tags), commit #$(git log --pretty=format:'%h' -n 1)."
}

###
## Git'r done
#

# read the conffile
if [ -e $confFile -a -r $confFile ]
then
	source $confFile
	echo "Parsing config file..."
        rvm_ENV
else
	echo "No confFile found; Remote copy DISABLED."
fi

# go back to where we came from
cd $PDIR

# Print version
printScriptver

###
## Exit gracefully
#
exit 0
