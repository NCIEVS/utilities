#!/bin/bash

# simple echo with a timestamp, with escapes enabled
timestamp () {
    echo -e $(date +%Y-%m-%d' '%X) :: "$@"
}

# used to append the session wget log to the persistent wget log
# the session log will be overwritten in subsequent runs
# call: appendToLog session.log persistent.log
appendToLog () {
    echo "" >> "$1"
    cat "$1" >> "$2"
}

################################################
# DIRS AND FILES
################################################
opsHome="/local/content"

scriptDir="$opsHome/virtuoso-misc/scripts"
binDir="$opsHome/virtuoso-misc/bin"
downloadDir="$opsHome/virtuoso-misc/download"
processingDir="$opsHome/virtuoso-misc/processing"
olderLoadDir="$opsHome/virtuoso-misc/olderloads"

dataLoadDir="$opsHome/virtuosoload"

logDir="$opsHome/virtuosodb/virtuosolog"
logfile="$logDir/processing.log"
wgetlog="$logDir/wget.log"
de2xlog="$logDir/de2x-err.log"


################################################
# DB AND PORTS; OF SUFFICIENT IMPORTANCE EVEN IF
# THEY ARE ONLY USED IN ONE SCRIPT
################################################
dbapd=virtDBA4prot_
virtport=1111
sparqlport=8890
