#!/bin/sh
#
# DMSAK - Drupal Multi-Site Admin Kit
# This script restores a Drupal "secure virtual folder" from a backup.
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
#     Usage: restore-web.sh [-h] [-d <path-to-drupal-dirs>] [-w <path-to-webs-dir>] [-v N] [-F] [-D] [-N] -b <backup-tarball> <website>
#
#   Example: restore-web.sh -d /var/wwwlib -w /var/www -v 6 -b example.com-201101051030-backup.tar.gz example.com
# Or simply: restore-web.sh -b example.com-201101051030-backup.tar.gz example.com
#
# This script assumes that Drupal folders are named "drupal-X" where X is the version number (5, 6 or 7).
#
# More info at: http://www.torvall.net

# Search for config file. First in /etc, then at the user's home and finally in the current working directory.
# If all fails, default values will be used.
if [ -e /etc/dmsak.cfg ]; then
	DMSAK_CONFIG=/etc/dmsak.cfg
else
	if [ -e ~/dmsak.cfg ]; then
		DMSAK_CONFIG=~/dmsak.cfg
	else
		if [ -e ./dmsak.cfg ]; then
			DMSAK_CONFIG=./dmsak.cfg
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
while getopts "d:w:v:b:FDNh" flag
do
	case $flag in
		d)
			DRUPAL_DIR="$OPTARG"
			;;
		w)
			WEBS_DIR="$OPTARG"
			;;
		v)
			DRUPAL_VERSION="$OPTARG"
			;;
		F)
			ONLY_FILES="TRUE"
			;;
		D)
			ONLY_DATABASE="TRUE"
			;;
		N)
			NO_BACKUP="TRUE"
			;;
		b)
			BACKUP_TARBALL="$OPTARG"
			;;
		h)
			HELP_REQUESTED="TRUE"
	esac
done

# Check if help was requested.
if [ "$HELP_REQUESTED" = "TRUE" ]; then
	echo 1>&2 "This script restores a Drupal \"secure virtual folder\" from a backup"
	echo 1>&2 "Copyright 2009 by António Maria Torre do Valle"
	echo 1>&2 "Released under the GNU General Public Licence (GPL)"
	echo 1>&2 "More info at: http://www.torvall.net"
	echo 1>&2 ""
	echo 1>&2 "Usage: $0 [-h] [-d <path-to-drupal-dirs>] [-w <path-to-webs-dir>] [-v N] [-F] [-D] [-N] -b <backup-tarball> <website>"
	echo 1>&2 ""
	echo 1>&2 "Parameters:"
	echo 1>&2 "  -h  Shows this help message"
	echo 1>&2 "  -d  Location of base Drupal directories (default: $WEBS_DIR)"
	echo 1>&2 "  -w  Directory where site is to be created at (default: $DRUPAL_DIR)"
	echo 1>&2 "  -v  Drupal version to use (5, 6 or 7, others still untested) (default: $DRUPAL_VERSION)"
	echo 1>&2 "  -F  Restore only files from the backup tarball"
	echo 1>&2 "  -D  Restore only the database from the backup tarball"
	echo 1>&2 "  -N  Do not backup existing data"
	echo 1>&2 "  -b  Filename of the backup tarball to restore (ex: example.com-201101051030-backup.tar.gz)"
	echo 1>&2 "  <website> is the domain name of the website to be created (ex: example.com)"
	echo 1>&2 "  Parameters -d, -w and -v are optional. See the config file (dmsak.cfg) to set the defaults."
	echo 1>&2 ""
	echo 1>&2 "Example: $0 -v 6 -b example.com-201101051030-backup.tar.gz example.com"
	exit 0
fi

# Reset argument position.
shift $((OPTIND-1)); OPTIND=1

# Get web name (last argument).
WEB_TO_RESTORE="$@"

# Check parameters.
if [ "$WEBS_DIR" = "" -o "$DRUPAL_DIR" = "" -o "$DRUPAL_VERSION" = "" -o "$BACKUP_TARBALL" = "" -o "$WEB_TO_RESTORE" = "" ]; then
	echo 1>&2 Usage: $0 -b example.com-201101051030-backup.tar.gz example.com
	exit 127
fi

# This is the complete path to the source Drupal folder.
# Remember that you must have a directory named "drupal-X" where X is its version (5, 6 or 7) at $DRUPAL_DIR.
DRUPAL_BASE_DIR="$DRUPAL_DIR/drupal-$DRUPAL_VERSION"

# Check if Drupal directory exists.
if [ ! -e $DRUPAL_BASE_DIR ]; then
	echo "Oops! Drupal directory $DRUPAL_BASE_DIR does not exist. Aborting."
	exit 127
fi

# Extract the tarball to the $TEMP_DIR.
tar zxf $BACKUP_TARBALL -C $TEMP_DIR

# Check if web directory already exists and move it out of the way to $TEMP_DIR.
if [ -e $WEBS_DIR/$WEB_TO_RESTORE ]; then
	mv $WEBS_DIR/$WEB_TO_RESTORE $TEMP_DIR/$WEB_TO_RESTORE-current
else
	# Or create a placeholder in $TEMP_DIR for any DB data that may exist.
	mkdir $TEMP_DIR/$WEB_TO_RESTORE-current
fi

# Restore database.
if [ "$ONLY_FILES" != "TRUE" ]; then
	# Get database name.
	DB_NAME=${WEB_TO_RESTORE//./_}
	DB_NAME=${DB_NAME//-/_}
	# Get database password interactively if not specified in config.
	if [ "$DB_PASS" = "" ]; then
		read -s -p "Enter $DB_USER's database password: " TEMP_PASS
		DB_PASS=${TEMP_PASS}
		echo
	fi

	# Check if database already exists.
	DATABASES=`mysql --host=$DB_HOST --user=$DB_USER --password=$DB_PASS -Bse 'show databases' | egrep -v 'information_schema|mysql|test'`
	for DATABASE in $DATABASES; do
		if [ "$DATABASE" = "$DB_NAME" ]; then
			# Backup database, if not specified otherwise.
			if [ "$NO_BACKUP" != "TRUE" ]; then
				echo "Backing up current database..."
				mysqldump --host=$DB_HOST --user=$DB_USER --password=$DB_PASS $DB_NAME > "$TEMP_DIR/$WEB_TO_RESTORE-current/$WEB_TO_RESTORE-db.sql"
				echo "Current database backed up."
			fi
			# Drop current database.
			mysqladmin --host=$DB_HOST --user=$DB_USER --password=$DB_PASS drop $DB_NAME
		fi
	done

	# Create DB, unless the user said not to.
	echo "Restoring database..."
	# Create database.
	mysqladmin --host=$DB_HOST --user=$DB_USER --password=$DB_PASS create $DB_NAME
	mysql --host=$DB_HOST --user=$DB_USER --password=$DB_PASS $DB_NAME < $TEMP_DIR/$WEB_TO_RESTORE/$WEB_TO_RESTORE-db.sql
	echo "Database $DB_NAME restored."

	# Grant permissions to user on the database.
	SQL_CMD="GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON $DB_NAME.* TO $DB_USER@$DB_HOST IDENTIFIED BY '$DB_PASS'; FLUSH PRIVILEGES;"
	mysql --silent --host=$DB_HOST --user=$DB_USER --password=$DB_PASS $DB_NAME << EOF
		$SQL_CMD
EOF
	echo "Permissions set on database."

fi

# Restore files.
if [ "$ONLY_DATABASE" != "TRUE" ]; then
	# Move the files from the backup to its destination.
	echo "Copying web files to $WEBS_DIR/$WEB_TO_RESTORE..."
	mv $TEMP_DIR/$WEB_TO_RESTORE $WEBS_DIR/$WEB_TO_RESTORE
	echo "Files restored."

	# Delete database backup from web dir.
	if [ -e $WEBS_DIR/$WEB_TO_RESTORE/$WEB_TO_RESTORE-db.sql ]; then
		rm $WEBS_DIR/$WEB_TO_RESTORE/$WEB_TO_RESTORE-db.sql
	fi

	# Check if link or directory already exists inside Drupal's sites folder.
	if [ ! -e $DRUPAL_BASE_DIR/sites/$WEB_TO_RESTORE ]; then
		# Link the restored sites/$WEB_TO_RESTORE directory from Drupal's sites dir.
		ln -s $WEBS_DIR/$WEB_TO_RESTORE/sites/$WEB_TO_RESTORE $DRUPAL_BASE_DIR/sites/$WEB_TO_RESTORE
	fi
fi

# Backup and compress existing data, if requested.
if [ "$NO_BACKUP" != "TRUE" ]; then
	# Rename folder.
	mv $TEMP_DIR/$WEB_TO_RESTORE-current $TEMP_DIR/$WEB_TO_RESTORE
	# Backup files.
	tar zcf $BACKUP_DIR/$WEB_TO_RESTORE-$CURR_DATE_STRING-backup.tar.gz -C $TEMP_DIR $WEB_TO_RESTORE
	CURR_DATE_STRING=`date +%Y%m%d%H%M`
	echo "Backed up data to $BACKUP_DIR/$WEB_TO_RESTORE-$CURR_DATE_STRING-backup.tar.gz"
	# Remove old web folder.
	rm -R $TEMP_DIR/$WEB_TO_RESTORE
else
	# Remove old web folder.
	rm -R $TEMP_DIR/$WEB_TO_RESTORE-current
fi

# Report success to the user.
echo "Web $WEB_TO_RESTORE restored."

echo
echo "All done."

exit 0
