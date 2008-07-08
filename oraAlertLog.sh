#!/bin/bash
# simple script to help find and tail the Oracle alert log
#
# Paul Gallagher gallagher.paul@gmail.com
# http://tardate.blogspot.com/2007/04/find-and-tail-oracle-alert-log.html
# 
# $Id: oraAlertLog.sh,v 1.9 2007/04/22 05:17:36 oracle Exp $
#

scriptPath=${0%/*}/
scriptName=${0#$scriptPath*}
cacheFile=${0%.*}.${ORACLE_SID}.conf
alertlog=

function setAlertLogName() {

	if [ "$ORACLE_SID" = "" ]
	then
		echo "ORACLE environment not available." >&2
		exit 1
	fi

	alertlog=$(sqlplus -S \/ as sysdba 2> /dev/null <<EOF
SET NEWPAGE 0
SET SPACE 0
SET LINESIZE 80
SET PAGESIZE 0
SET ECHO OFF
SET FEEDBACK OFF
SET VERIFY OFF
SET HEADING OFF
SELECT value 
FROM   v\$parameter 
WHERE  name = 'background_dump_dest';
EOF
)
	
	if [ $(echo $alertlog | grep -c "ORA-\|ERR") -gt 0 ]
	then
		echo "ORACLE not available. Checking for cached settings.." >&2
		alertlog=
	fi
	if [ "$alertlog" = "" ]
	then
		. $cacheFile
	else
		alertlog=${alertlog}/alert_${ORACLE_SID}.log
	fi
	if [ "$alertlog" = "" ]
	then
		echo "Could not determine alert log location." >&2
		exit 1
	else
		echo "alertlog=${alertlog}" > $cacheFile
	fi

}

function info() {
	setAlertLogName
	echo "ORACLE_HOME = $ORACLE_HOME"
	echo "ORACLE_SID  = $ORACLE_SID"
	echo "ALERT LOG   = ${alertlog}"
}

function tailLog() {
	setAlertLogName
	tail -f $alertlog
}

function usage() {
	cat <<EOF

  $0 -i    ... show Oracle environment and log info
  $0 -f    ... tail the alert log

EOF
	exit
}

# handle case of no parameters
if [ $# -eq 0 ]
then
	usage
fi

# process parameters
while getopts "if" options
do
	case $options in
    	f ) 
		tailLog
		;;
    	i )
		info
		;;
	\? )
		usage
		;;
	esac
done

