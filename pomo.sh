#!/bin/sh
HOUR=0
MIN=25
SEC=0
BREAK_TIMER=5 # duration of break time
LOOPS=1 #number of times to loop
RED='\033[0;31m'
LONG_BREAK=25
TAKE_LONG=
WAS_RESTARTED=
INIT_MIN_VAL=
FILE="/tmp/saved_state.tmp"
echoInfo(){
	echo $1 > "$FILE"
	echo $2 >> "$FILE"
	echo $3 >> "$FILE"
	echo $4 >> "$FILE"
	echo $5 >> "$FILE"
	echo $6 >> "$FILE"
	exit 1
}
finishTimer () {
	tput sgr0
	tput cup $( tput lines ) 0
	tput cnorm
}
timer(){
	local hr=$1; local min=$2; local sec=$3
	cols=$( tput cols )
	rows=$( tput lines )
	middle_row=$(( $rows / 2 ))
	middle_col=$(( ($cols /2) - 4 ))
	tput clear
	tput bold
	tput civis
	while [ $hr -ge 0 ]; do
		while [ $min -ge 0 ]; do
			 while [ $sec -ge 0 ]; do
			     if [ $hr -eq 0 ] && [ $min -eq 0 ]; then
				 tput setab 3    
				 tput clear
			     fi
			     if [ $hr -eq 0 ] && [ $min -eq 0 ] && [ $sec -le 10 ]; then
				 tput setab 1
				 tput clear
			     fi
				     tput cup $middle_row $middle_col
				     printf "%02d:%02d:%02d" $hr $min $sec
				     trap "save $hr $min $sec $LOOPS $BREAK_TIMER $TAKE_LONG $MIN" INT
				     sec=$((sec-1))
				 sleep 1
				 done
			 sec=59
			 min=$((min-1))
		done
		min=59
		hr=$((hr-1))
	done
	echo "${RESET}"
	finishTimer
}
save(){
	if [ -e $FILE ]; then
		echoInfo $1 $2 $3 $4 $5
	else
		touch "$FILE"
		echoInfo $1 $2 $3 $4 $5
	fi
}
# main chunk
if [ $# -eq 0 ]; then
	TAKE_LONG=0
fi
while [ $# -gt 0 ]; do
	case "$1" in
		-h)
			echo "this is a pomdoro timer!"
			echo "\t\t\t-h\t\tprint this help message"
			echo "\t\t\t-hr\t\tadd hours to countdown"
			echo "\t\t\t-m\t\tset the minutes(default 25)"
			echo "\t\t\t-l\t\tenable multiple work break loops"
			echo "\t\t\t-r\t\tresume from terminated timer"
			shift 1
			exit 1
			;;
		-hr)
			HOUR=$2
			shift 2
			;;
		-m)
			MIN=$2
			shift 2
			;;
		-l)
			LOOPS=$2 # takes the number of loops
			if [ $2 -gt 4 ]; then
				TAKE_LONG=1
			fi
			shift 2
			;;
		-r)
			if [ -e $FILE ]; then
				HOUR=$(sed -n '1p' "$FILE")
				MIN=$(sed -n '2p' "$FILE")
				SEC=$(sed -n '3p' "$FILE")
				LOOPS=$(sed -n '4p' "$FILE")
				BREAK_TIMER=$(sed -n '5p' "$FILE")
				TAKE_LONG=$(sed -n '6p' "$FILE")
				WAS_RESTARTED=1
				INIT_MIN_VAL=$(tail -n 1 "$FILE")
				rm "$FILE"
				shift 1
			fi
			;;
		-b)
			BREAK_TIMER=$2
			shift 2
			;;

		*)
			echo "Not a recognized flag"
			echo "try -h for help"
			return 0
	esac
done

while [ $LOOPS -gt 0 ]; do
	timer $HOUR $MIN $SEC
	sleep 3
	if [ $TAKE_LONG -eq 1 && $(($LOOPS % 4)) -eq 0 || $LOOPS -eq 1 ]; then
		timer 0 $TAKE_LONG 0
		LOOPS=$(($LOOPS-1))
	else
		timer 0 $BREAK_TIMER 0
		LOOPS=$(($LOOPS-1))
	fi
	if [ $WAS_RESTARTED -eq 1 ]; then
		MIN=$INIT_MIN_VAL
		SEC=0
		unset WAS_RESTARTED
	fi
	sleep 3
done
rows=$( tput lines )
middle_row=$(( $rows / 2 ))
tput clear
tput cup $middle_row $middle_col
echo "Great job! your timer is over."
