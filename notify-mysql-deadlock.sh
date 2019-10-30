#!/bin/bash
#
# Detects mysql deadlocks and notify developers by email
# Notification sent on new deadlocks only
# monuser must have "PROCESS" permission in mysql server
# Set EXCLUDE_PTRN to avoid alerting if the pattern was found
#
blk=$(tput blink)
bld=$(tput bold)           	 # Bold
red=${bld}$(tput setaf 1)    # Red
grn=${bld}$(tput setaf 2)    # Green
yel=${bld}$(tput setaf 3)    # Yellow
blu=${bld}$(tput setaf 4)    # Blue
mag=${bld}$(tput setaf 5)    # Purple
cyn=${bld}$(tput setaf 6)    # Cyan
wht=${bld}$(tput setaf 7)    # White
off=$(tput sgr0)             # Text reset

MYCONF="/Users/usernameHere/my.conn.cnf"

tmp=/tmp/.${host}.output.txt

#TO="dev@dom.local"
#FROM="noreply@dom.local"
#SUB="$host: Deadlock found"
echo -e "\nEnter the ${cyn}MySQL DB Server Name (or IP)${off} for Deadlocks detecting followed by [ENTER]:"
read DBSERVERNAME;
if [[ -z ${DBSERVERNAME} ]] 
then 
	echo -e "MySQL DB Server cannot be empty\n Starting again...\n\n"
	exit 1
fi

#-- do not alert if the following pattern was found
EXCLUDE_PTRN=""

#[ "x$host" = "x" ] && exit
#mysql --defaults-extra-file=${MYCONF} -h $DBSERVERNAME 
#mysql -h $host -u $user --password=$pass -be 'show engine innodb status \G' \
#    | awk '/TRANSACTIONS/{flag=0}flag;/LATEST DETECTED DEADLOCK/{flag=1}' > $tmp
while true
do 
	echo "${mag}[`date +"%Y-%m-%d %H:%M:%S"`]${off}${cyn}Dumping Last Deadlock Detected Detail Information ${off}"
	mysql --defaults-extra-file=${MYCONF} -h $DBSERVERNAME  -be 'show engine innodb status \G' | awk '/TRANSACTIONS/{flag=0}flag;/LATEST DETECTED DEADLOCK/{flag=1}' > $tmp
	[ -s $tmp ] || exit

	if [ ! "x${EXCLUDE_PTRN}" = "x" ]; then
	    grep -qiE "${EXCLUDE_PTRN}" $tmp
	    if [ $? -eq 0 ]; then
	        /bin/rm -f $tmp
	        exit
	    fi
	fi

	timestamp=$(head -n 2 $tmp | tail -n 1 | sed -e 's/ /_/g')
	if [ -s "$tmp-$timestamp" ]; then
	    /bin/rm -f $tmp
	    exit
	fi

	/bin/rm -f $tmp-*
	cat $tmp
	echo "${yel}Sleeping 30 seconds...${off}"
	sleep 30s
done
#cat $tmp | mail -s "${SUB}" -r "${FROM}" $TO
#/bin/mv $tmp "$tmp-$timestamp"
