#!/bin/sh
#
# DMSAK - Drupal Multi-Site Admin Kit
# This script backs up a Drupal "secure virtual folder".
#
# Copyright 2009 António Maria Torre do Valle
# Released under the GNU General Public Licence (GPL): http://www.gnu.org/licenses/gpl-3.0.html
#
# This script is part of the Drupal Multi-Site Admin Kit (DMSAK).
# DMSAK is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# DMSAK is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with DMSAK. If not, see <http://www.gnu.org/licenses/>.
#
#     Usage: backup-web.sh [-h] [-w <path-to-webs-dir>] [-b <path-to-backup-dir>] <website>
#
#   Example: backup-web.sh -w /var/www -b /var/backups example.com
# Or simply: backup-web.sh example.com
#
# More info at: http://www.torvall.net

# Search for config file. First in the current working directory, then at the user's home and finally in /etc.
# If all fails, default values will be used.
if [ -e ./dmsak.cfg ]; then
	DMSAK_CONFIG=./dmsak.cfg
else
	if [ -e ~/dmsak.cfg ]; then
		DMSAK_CONFIG=~/dmsak.cfg
	else
		if [ -e /etc/dmsak.cfg ]; then
			DMSAK_CONFIG=/etc/dmsak.cfg
		else
			# Set reasonable values for the defaults.
			DRUPAL_VERSION="6"
			DRUPAL_DIR="/var/lib"
			WEBS_DIR="/var/www"
			BACKUP_DIR="/root"
			TEMP_DIR="/tmp"
			DB_HOST="localhost"
			DB_USER="root"
			DB_PASS=""
		fi
	fi
fi

# Include config file.
if [ "$DMSAK_CONFIG" ]; then
	. $DMSAK_CONFIG
fi

# Parse parameters.
while getopts "w:h:b:" flag
do
	case $flag in
		w)
			WEBS_DIR="$OPTARG"
			;;
		h)
			HELP_REQUESTED="TRUE"
			;;
		b)
			BACKUP_DIR="$OPTARG"
			;;
	esac;
done

# Check if help was requested.
if [ "$HELP_REQUESTED" = "TRUE" ]; then
	echo 1>&2 "This script backs up a Drupal \"secure virtual folder\"."
	echo 1>&2 "Copyright 2009 by António Maria Torre do Valle"
	echo 1>&2 "Released under the GNU General Public Licence (GPL)"
	echo 1>&2 "More info at: http://www.torvall.net"
	echo 1>&2 ""
	echo 1>&2 "Usage: $0 [-h] [-w <path-to-webs-dir>] <website>"
	echo 1>&2 ""
	echo 1>&2 "Parameters:"
	echo 1>&2 "  -b  Specify the directory to hold the backup (default: $BACKUP_DIR)"
	echo 1>&2 "  -h  Shows this help message"
	echo 1>&2 "  -w  Directory containing websites (default: $WEBS_DIR)"
	echo 1>&2 "  <website> is the domain name of the website to be backed-up (ex: example.com)"
	echo 1>&2 "  Parameters -b,-w are optional. See the config file (dmsak.cfg) to set the default."
	echo 1>&2 ""
	echo 1>&2 "Example: $0 example.com"
	exit 0
fi

# Reset argument position.
shift $((OPTIND-1)); OPTIND=1

# Get web name (last argument).
WEB_TO_BACKUP="$@"

# Check parameters.
if [ "$WEBS_DIR" = "" -o "$WEB_TO_BACKUP" = "" ]; then
	echo 1>&2 Usage: $0 -w /var/www example.com
	exit 127
fi

# Check if web directory exists.
if [ ! -e $WEBS_DIR/$WEB_TO_BACKUP ]; then
	echo "Oops! Directory $WEBS_DIR/$WEB_TO_BACKUP does not exist. Aborting."
	exit 127
fi

# Get database password interactively if not specified in config.
if [ "$DB_PASS" = "" ]; then
	read -s -p "Enter $DB_USER's database password: " TEMP_PASS
	DB_PASS=${TEMP_PASS}
	echo
fi

# Get database name.
DB_NAME=${WEB_TO_BACKUP//./_}
DB_NAME=${DB_NAME//-/_}

# Backup database.
CURR_DATE_STRING=`date +%Y%m%d%H%M`
echo "Backing up data..."
mysqldump --host=$DB_HOST --user=$DB_USER --password=$DB_PASS $DB_NAME > "$WEBS_DIR/$WEB_TO_BACKUP/$WEB_TO_BACKUP-db.sql"
echo "Database exported."

# Backup files.
tar zcf $BACKUP_DIR/$WEB_TO_BACKUP-$CURR_DATE_STRING-backup.tar.gz -C $WEBS_DIR $WEB_TO_BACKUP
echo "Backed up data to $BACKUP_DIR/$WEB_TO_BACKUP-$CURR_DATE_STRING-backup.tar.gz"

echo
echo "All done."

exit 0
