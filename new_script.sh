#!/bin/bash
# ---------------------------------------------------------------------------
# new_script - Bash shell script template generator

# Copyright 2012, William Shotts (bshotts@users.sourceforge.net)

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at (http://www.gnu.org/licenses/) for
# more details.

# Usage: new_script [-h|--help] [-q|--quiet] [-s|--root] [script]

# Revision history:
# 2012-05-14    Created
# ---------------------------------------------------------------------------

PROGNAME=${0##*/}
VERSION="3.0"
SCRIPT_SHELL=${SHELL}

# Make some pretty date strings
DATE=$(date +'%Y-%m-%d')
YEAR=$(date +'%Y')

# Get user's real name from passwd file
AUTHOR=$(awk -v USER=$USER 'BEGIN { FS = ":" } $1 == USER { print $5 }' < /etc/passwd)

# Construct the user's email address from the hostname or the REPLYTO
# environment variable, if defined
EMAIL_ADDRESS="<${REPLYTO:-${USER}@$HOSTNAME}>"

# Arrays for command-line options and option arguments
declare -a opt opt_desc opt_long opt_arg opt_arg_desc


clean_up() { # Perform pre-exit housekeeping
	return
}

error_exit() {
	echo -e "${PROGNAME}: ${1:-"Unknown Error"}" >&2
	clean_up
	exit 1
}

graceful_exit() {
	clean_up
	exit
}

signal_exit() { # Handle trapped signals
	case $1 in
		INT)    error_exit "Program interrupted by user" ;;
		TERM)   echo -e "\n$PROGNAME: Program terminated" >&2 ; graceful_exit ;;
		*)      error_exit "$PROGNAME: Terminating on unknown signal" ;;
	esac
}

usage() {
	echo "Usage: ${PROGNAME} [-h|--help ] [-q|--quiet] [-s|--root] [script]"
}

help_message() {
	cat <<- -EOF-
	${PROGNAME} ${VERSION}
	Bash shell script template generator.

	$(usage)

	Options:

	-h, --help    Display this help message and exit.
	-q, --quiet   Quiet mode. No prompting. Outputs default script.
	-s, --root    Output script requires root previleges to run.

	-EOF-
}

insert_license() {

	if [[ -z $script_license ]]; then
		echo "# All rights reserved."
		return
	fi
	cat <<- _EOF_
	
	# This program is free software: you can redistribute it and/or modify
	# it under the terms of the GNU General Public License as published by
	# the Free Software Foundation, either version 3 of the License, or
	# (at your option) any later version.

	# This program is distributed in the hope that it will be useful,
	# but WITHOUT ANY WARRANTY; without even the implied warranty of
	# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	# GNU General Public License at (http://www.gnu.org/licenses/) for
	# more details.
	_EOF_
}

insert_usage() {

	echo -e "usage() {\n\techo \"$usage_str\"\n}"
}

insert_help_message() {

	local arg i long

	echo -e "help_message() {"
	echo -e "\tcat <<- _EOF_"
	echo -e "\t\$PROGNAME ver. \$VERSION"
	echo -e "\t$script_purpose"
	echo -e "\n\t\$(usage)"
	echo -e "\n\tOptions:"
	i=0
	while [[ ${opt[i]} ]]; do
		long=
		arg=
		[[ ${opt_long[i]} ]] && long=", --${opt_long[i]}"
		[[ ${opt_arg[i]} ]] && arg=" ${opt_arg[i]}"
		echo -e "\t-${opt[i]}$long$arg\t${opt_desc[i]}"
		[[ ${opt_arg[i]} ]] && \
			echo -e "\t\tWhere '${opt_arg[i]}' is the ${opt_arg_desc[i]}."
		((++i))
	done
	[[ $root_mode ]] && \
		echo -e "\n\tNOTE: You must be the superuser to run this script."
	echo -e "\n\t_EOF_"
	echo -e "\treturn\n}"
}

insert_root_check() {

	if [[ $root_mode ]]; then
		echo -e "# Check for root UID"
		echo -e "if [[ \$(id -u) != 0 ]]; then"
		echo -e "\terror_exit \"You must be the superuser to run this script.\""
		echo -e "fi"
	fi
}

insert_parser() {

	local i
	
	echo -e "while [[ -n \$1 ]]; do\n\tcase \$1 in"
	echo -e "\t\t-h | --help)\thelp_message; graceful_exit ;;"
    echo -e "\t\t-d | --debug)\tver_lvl=\$dbg_lvl; shift ;;"
	echo -e "\t\t-q | --quiet)\tver_lvl=\$err_lvl; shift ;;"
	echo -e "\t\t-v | --verbosity)\tver_lvl=\$2; shift ;;"
	echo -e "\t\t-l | --logfile)\tlog_file=\$2; NOW=\$(date +\"%d-%m-%Y %H:%M:%S\"); exec 3>>\$2; shift ;;"
	
	for (( i = 5; i < ${#opt[@]}; i++ )); do
		echo -ne "\t\t-${opt[i]}"
		[[ -n ${opt_long[i]} ]] && echo -ne " | --${opt_long[i]}"
		echo -ne ")\techo \"${opt_desc[i]}\""
		[[ -n ${opt_arg[i]} ]] && echo -ne "; shift; ${opt_arg[i]}=\"\$1\""
		echo " ;;"
	done
	echo -e "\t\t-* | --*)\tusage; error_exit \"Unknown option \$1\" ;;"
	echo -e "\t\t*)\t\techo \"Argument \$1 to process...\" ;;"
	echo -e "\tesac\n\tshift\ndone"
}

write_script() {

#############################################################################
# START SCRIPT TEMPLATE
#############################################################################
cat << _EOF_
#! $SCRIPT_SHELL
# ---------------------------------------------------------------------------
# $script_name - $script_purpose

# Copyright $YEAR, $AUTHOR $EMAIL_ADDRESS
$(insert_license)

# Usage: $script_name$usage_message

# Revision history:
# $DATE	Created 
# ---------------------------------------------------------------------------

PROGNAME=\${0##*/}
VERSION="0.1"

## PUT FUNCTIONS HERE AND ADD TO main()

main(){
	notify "Fill this main method with your own methods"
	error "hi"
	warn "hi"
	debug "hi"
	inf "hi"
}

## END of Script Specific Code

clean_up() { # Perform pre-exit housekeeping
	debug "Cleaning up..."
	return
}

error_exit() {
	error "\${PROGNAME}: \${1:-"Unknown Error"}" >&2
	clean_up
	exit 1
}

graceful_exit() {
	clean_up
	debug "...Finished"
	exit
}

signal_exit() { # Handle trapped signals
	case \$1 in
		INT)    error_exit "Program interrupted by user" ;;
		TERM)   echo -e "\n\$PROGNAME: Program terminated" >&2 ; graceful_exit ;;
		*)      error_exit "\$PROGNAME: Terminating on unknown signal" ;;
	esac
}

require() { 
    if command -v \$1 >/dev/null; then
      debug ""\$1" found in path!"
    else
      error ""\$1" is not in your path. Please set the PATH correctly."
      exit $?
    fi
}

usage() {
	echo -e "Usage: \$PROGNAME$usage_message"
}

# Set Colour Variables
# Usage: FBLK (front Black), BRED (Background Red), TBLD (Text Bold)
set_colours() {
  local COLOURS=(BLK RED GRN YLW BLU MAG CYN WHT)
  local i SGRS=(RST BLD DIM ITA UND BLINK ___ INV)
  for (( i=0; i<8; i++ )); do
    eval "F\${COLOURS[i]}=\"\e[3\${i}m\""
    eval "FL\${COLOURS[i]}=\"\e[9\${i}m\""
    eval "B\${COLOURS[i]}=\"\e[4\${i}m\""
    eval "BL\${COLOURS[i]}=\"\e[10\${i}m\""
    eval   "T\${SGRS[i]}=\"\e[\${i}m\""
  done
}

# Set Logging
exec 3>&2 # logging stream (file descriptor 3) defaults to STDERR
silent_lvl=0; err_lvl=1; wrn_lvl=2; dbg_lvl=3; inf_lvl=4 # Set logging levels
notify() { log \$silent_lvl "\${TBLD}[NOTE]:\${TRST} \$1"; } # Always prints
error() { log \$err_lvl "\${TRST}\${FRED}\${TBLD}[ERROR]: \${TRST}\${FRED}\$1\${TRST}"; }
warn() { log \$wrn_lvl "\${TRST}\${FYLW}\${TBLD}[WARNING]:\${TRST} \$1"; }
debug() { log \$dbg_lvl "\${TRST}\${FCYN}\${TBLD}[DEBUG]:\${TRST} \$1"; }
inf() { log \$inf_lvl "\${TRST}\${FWHT}\${TBLD}[INFO]:\${TRST} \$1"; } # "info" is already a command
log() {
	if [ -z \$ver_lvl ]; then ver_lvl=2; fi # default to show warnings
    if [ \$ver_lvl -ge \$1 ]; then
        # Expand escaped characters, wrap at 70 chars, indent wrapped lines
        printf "\$NOW \$2\n" | fold -w70 -s >&3 #| sed '2~1s/^/  /' >&3
    fi
}

$(insert_help_message)

# Trap signals
trap "signal_exit TERM" TERM HUP
trap "signal_exit INT"  INT

$(insert_root_check)

# Parse command-line
$(insert_parser)


startup(){
	if [ -z \$log_file ]; then set_colours; fi # if no log file, set colours
	debug "\$PROGNAME ver. \$VERSION run by \$USER"
	debug "Verbosity level set at \$ver_lvl"
	# Source Config File
	if [[ -e ~/."\$filename".conf ]]; then source ~/."\$filename".conf
	elif [[ -e /etc/"\$filename".conf ]]; then source /etc/"\$filename".conf
	fi
}

# Main logic
startup
main
graceful_exit

_EOF_
#############################################################################
# END SCRIPT TEMPLATE
#############################################################################

}

check_filename() {

	local filename=$1
	local pathname=${filename%/*} # Equals filename if no path specified

	if [[ $pathname != $filename ]]; then
		if [[ ! -d $pathname ]]; then
			[[ $quiet_mode ]] || echo "Directory $pathname does not exist."
			return 1
		fi
	fi
	if [[ -n $filename ]]; then
		if [[ -e $filename ]]; then
			if [[ -f $filename && -w $filename ]]; then
				[[ $quiet_mode ]] && return 0
				read -p "File $filename exists. Overwrite [y/n] > "
				[[ $REPLY =~ ^[yY]$ ]] || return 1
			else
				return 1
			fi
		fi
	else
		[[ $quiet_mode ]] && return 0 # Empty file name allowed in quiet mode
		return 1
	fi
}

read_option() {

	local i=$((option_count + 1))

	echo -e "\nOption $i:"
	read -p "Enter option letter [a-z] (Enter to end) > " 
	[[ -n $REPLY ]] || return 1 # prevent array element if REPLY is empty
	opt[i]=$REPLY
	read -p "Description of option -------------------> " opt_desc[i]
	read -p "Enter long alternate name (optional) ----> " opt_long[i]
	read -p "Enter option argument (if any) ----------> " opt_arg[i]
	[[ -n ${opt_arg[i]} ]] && \
	read -p "Description of argument (if any)---------> " opt_arg_desc[i]
	return 0 # force 0 return status regardless of test outcome above
}

# Trap signals
trap "signal_exit TERM" TERM HUP
trap "signal_exit INT"  INT

# Parse command-line
quiet_mode=
root_mode=
script_license=
while [[ -n $1 ]]; do
	case $1 in
		-h | --help)    help_message; graceful_exit ;;
		-q | --quiet)   quiet_mode=yes ;;
		-s | --root)    root_mode=yes ;;
		-* | --*)       usage; error_exit "Unknown option $1" ;;
		*)              tmp_script=$1; break ;;
	esac
	shift
done

# Main logic

if [[ $quiet_mode ]]; then
	script_filename="$tmp_script"
	check_filename "$script_filename" || \
		error_exit "$script_filename is not writable."
	script_purpose="[Enter purpose of script here.]"
else
	# Get script filename
	script_filename=
	while [[ -z $script_filename ]]; do
		if [[ -n $tmp_script ]]; then
			script_filename="$tmp_script"
			tmp_script=
		else
			read -p "Enter script output filename: " script_filename
		fi
		if ! check_filename "$script_filename"; then
			echo "$script_filename is not writable."
			echo -e "Please choose another name.\n"
			script_filename=
		fi
	done

	# Purpose
	read -p "Enter purpose of script: " script_purpose

	# License
	read -p "Include GPL license header [y/n]? > "
	[[ $REPLY =~ ^[yY]$ ]] && script_license="GPL"
	
	# Requires superuser?
	read -p "Does this script require superuser privileges [y/n]? > "
	[[ $REPLY =~ ^[yY]$ ]] && root_mode="yes"

	# Command-line options
	option_count=0
	read -p "Does this script support command-line options [y/n]? > "
	[[ $REPLY =~ ^[yY]$ ]] && while read_option; do ((++option_count)); done
fi

script_name=${script_filename##*/} # Strip path from filename
script_name=${script_name:-"[Untitled Script]"} # Supply default if enmpty

# "help" and "verbose" option included by default
opt[0]="h"
opt_long[0]="help"
opt_desc[0]="Display this help message and exit."
opt[1]="d"
opt_long[1]="debug"
opt_desc[1]="Turn debug on"
opt[2]="q"
opt_long[2]="quiet"
opt_desc[2]="Turn quietness on"
opt[3]="v"
opt_long[3]="verbosity"
opt_desc[3]="Set verbosity"
opt_arg[3]="verbosity_level"
opt_arg_desc[3]="numeric level (0-4) of verbosity"
opt[4]="l"
opt_long[4]="log"
opt_desc[4]="Set log file"
opt_arg[4]="log_file"
opt_arg_desc[4]="name of the log file"

# Create usage message
usage_message=	
i=0
while [[ ${opt[i]} ]]; do
	arg="]"
	[[ ${opt_arg[i]} ]] && arg=" ${opt_arg[i]}]"
	usage_message="$usage_message [-${opt[i]}"
	[[ ${opt_long[i]} ]] && usage_message="$usage_message|--${opt_long[i]}"
	usage_message="$usage_message$arg"
	((++i))
done

# Generate script
if [[ $script_filename ]]; then # Write script to file
	write_script > "$script_filename"
	chmod +x "$script_filename"
else
	write_script # Write script to stdout
fi

graceful_exit