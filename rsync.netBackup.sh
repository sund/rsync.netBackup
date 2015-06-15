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
excludeFile="$PDIR/excludeFiles.txt"

#source read_ini.sh
. $PDIR/read_ini.sh

###
## Functions
#

checkSize() {
    echo ===== Sizing =====
    echo
}

sectionRsyncVars() {
  echo Section list as string: ${SectionList[@]}
  echo Total Sections: $sectionCount
  while [ "$index" -lt "$sectionCount" ]; do
    echo -e "index: $index\tvalue: ${SectionList[$index]}"
    let "index++"
  done
  echo "---"
}

sectionRsync() {
  SectionList=(`echo ${INI__ALL_SECTIONS}`)
  sectionCount=${#SectionList[@]}
  index=0

  # for troubleshooting
  if [[ ${INI__global__enableDebug} == "true" || ${INI__global__enableDebug} = 1 ]]
	then
    sectionRsyncVars
  fi

  for (( sCount=2; $sCount < $sectionCount; sCount++ ))
  do

    if [[ ${INI__global__enableDebug} == "true" || ${INI__global__enableDebug} = 1 ]]
  	then
      # for troubleshooting
      echo "---"
      echo scount: $sCount
      echo section: ${SectionList[$sCount]}
      echo "---"
    fi

    forSource="INI__${SectionList[$sCount]}__localSource"
    forDestination="INI__${SectionList[$sCount]}__remoteDestination"

    if [[ ${INI__global__enableDebug} == "true" || ${INI__global__enableDebug} = 1 ]]
  	then
      # for troubleshooting
      echo ${!forSource}
      echo ${!forDestination}
    fi

    echo =============================================================
    echo "Starting rsync for section: ${SectionList[$sCount]}"
    rsyncUP ${!forSource} ${!forDestination}

  done


}

rsyncConnection() {
  echo -e "Testing connection to ${INI__server__rsyncUSER}@${INI__server__rsyncSERVER}..."
  ssh ${INI__server__rsyncSERVER} -l ${INI__server__rsyncUSER} -T ls > /dev/null
  if [ $? == 0 ]
    then
    echo "  [SUCCESS]"
  fi
}

rsyncUP() {
# rsync given local to remote paths
    echo -e "Start rsync of $1 to \n${INI__server__rsyncUSER}@${INI__server__rsyncSERVER}:/$2\n${INI__server__rsyncSSHKEY}"
    rsync -raz --verbose ${sshKeyUsage} --exclude-from=$excludeFile $1/ "${INI__server__rsyncUSER}"@"${INI__server__rsyncSERVER}":"$2"
    echo =============================================================
}

rsyncQuota() {
#quota check
	if [[ ${INI__global__checkQuota} == "true" || ${INI__global__checkQuota} = 1 ]]
	then
	    echo =============================================================
	    echo -e "Quota check: \n${INI__server__rsyncUSER}@${INI__server__rsyncSERVER}:$remoteDestination"
		ssh $sshKeyQuota "${INI__server__rsyncUSER}"@"${INI__server__rsyncSERVER}" "quota"
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
      echo "This is $OSNAME."
        ;;
    "Darwin")
    echo "This is $OSNAME."
        ;;
    "SunOS")
    echo "This is $OSNAME."
        ;;
    *)
    echo "This is $OSNAME; an unknown and possibly unsupported distribution."
        ;;
esac
}

printVars() {
  echo =============================================================
  echo "         ============== Variables ================"
  echo "All Vars: "${INI__ALL_VARS}
  echo "All Sections: "${INI__ALL_SECTIONS}
  echo "Number of Sections: "${INI__NUMSECTIONS}
  echo "rsync user ${INI__server__rsyncUSER}"
  echo "rsync server ${INI__server__rsyncSERVER}"
  echo "rsync SSH key path: ${INI__server__rsyncSSHKEY}"
  echo "Check Quota? ${INI__global__checkQuota}"
  echo "default Destination: ${INI__defaultBackup__remoteDestination}"
  echo "default Local Source: ${INI__defaultBackup__localSource}"
  if [ -z "${INI__server__rsyncUSER}" ]; then echo "rsyncUSER is unset"; else echo "rsyncUSER is set to '${INI__server__rsyncUSER}'"; fi
  if [ -z "${INI__server__rsyncSERVER}" ]; then echo "rsyncSERVER is unset"; else echo "rsyncSERVER is set to '${INI__server__rsyncSERVER}'"; fi
  if [ -z "${INI__server__rsyncSSHKEY}" ]; then echo "rsyncSSHKEY is unset"; else echo "rsyncSSHKEY is set to '${INI__server__rsyncSSHKEY}'"; fi
  echo =============================================================
}

timeTrap() {
  trap times EXIT
}

###
## Git'r done
#

# what type/kind of host are we on
determineOS

# read the conffile
if [ -e $confFile -a -r $confFile ]
then
  echo "Parsing config file..."
  read_ini "$confFile"

  ## for debugging purposes
  if [[ ${INI__global__enableDebug} == "true" || ${INI__global__enableDebug} = 1 ]]
	then
    printVars
  fi

else
	echo "No config file found; Please create a config file."
  echo "See https://github.com/sund/rsync.netBackup/wiki/Configuration"
  exit 1
fi

if [[ -z "${INI__server__rsyncSSHKEY}" ]] # if var is NOT empty
then
  echo "using default key"
  export sshKeyUsage=""
else
  echo -n "config supplied valid ssh key "
  echo ${INI__server__rsyncSSHKEY}
  export sshKeyUsage="-e ssh -i ${INI__server__rsyncSSHKEY}"
  export sshKeyQuota="-i ${INI__server__rsyncSSHKEY}"
fi

#check account creds
if [ -n "${INI__server__rsyncUSER}" ] && [ -n "${INI__server__rsyncSERVER}" ]
  then
  rsyncConnection
else
  echo "Error connecting to $rsyncUSER@$rsyncSERVER."
  echo "See https://github.com/sund/rsync.netBackup/wiki/Configuration"
  exit 1
fi

#Rsync it up.
sectionRsync

# size it
rsyncQuota

# Print version
printScriptver

###
## Exit gracefully
#
## for debugging purposes
if [[ ${INI__global__enableDebug} == "true" || ${INI__global__enableDebug} = 1 ]]
then
  timeTrap
fi

exit 0
