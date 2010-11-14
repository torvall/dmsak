#!/bin/sh
#
# DMSAK - Drupal Multi-Site Admin Kit
# This script deletes a Drupal "secure virtual folder".
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
#     Usage: rmweb.sh [-d <path-to-drupal-dirs>] [-w <path-to-webs-dir>] [-v N] [-R] [-N] <website>
#
#   Example: rmweb.sh -d /var/wwwlib -w /var/www -v 5 -R -N example.com
# Or simply: rmweb.sh example.com
#
# This script assumes that Drupal folders are named "drupal-X" where X is the version number (5 or 6).
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
			DRUPAL_DIR="/var/wwwlib"
			WEBS_DIR="/var/www"
			DRUPAL_VERSION="5"
			BACKUP_DIR="/var/www"
			TEMP_DIR="/tmp"
		fi
	fi
fi

# Include config file.
if [ "$DMSAK_CONFIG" ]; then
	. $DMSAK_CONFIG
fi

# Parse parameters.
while getopts "d:w:v:RNh" flag
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
		R)
			REMOVE_FOLDER="TRUE"
			;;
		N)
			NO_BACKUP="TRUE"
			;;
		h)
			HELP_REQUESTED="TRUE"
	esac
done

# Check if help was requested.
if [ "$HELP_REQUESTED" = "TRUE" ]; then
	echo 1>&2 "This script deletes a Drupal \"secure virtual folder\""
	echo 1>&2 "Copyright 2009 by António Maria Torre do Valle"
	echo 1>&2 "Released under the GNU General Public Licence (GPL)"
	echo 1>&2 "More info at: http://www.torvall.net"
	echo 1>&2 ""
	echo 1>&2 "Usage: $0 [-d <path-to-drupal-dirs>] [-w <path-to-webs-dir>] [-v N] [-R] [-N] <website>"
	echo 1>&2 ""
	echo 1>&2 "Parameters:"
	echo 1>&2 "  -h  Shows this help message"
	echo 1>&2 "  -d  Location of base Drupal directories (default: $DRUPAL_DIR)"
	echo 1>&2 "  -w  Directory containing websites (default: $WEBS_DIR)"
	echo 1>&2 "  -v  Drupal version (5 or 6, others still untested) (default: $DRUPAL_VERSION)"
	echo 1>&2 "  -R  Force deletion of web folder. Without this option, the script only removes the symlink from Drupal's base folder."
	echo 1>&2 "  -N  Do not backup folder prior to removal (only effective with -R)"
	echo 1>&2 "  <website> is the domain name of the website to be deleted (ex: example.com)"
	echo 1>&2 "  Parameters -d, -w and -v are optional. See the config file (dmsak.cfg) to set the defaults."
	echo 1>&2 ""
	echo 1>&2 "Example: $0 -d /var/wwwlib -w /var/www -v 5 -R -N example.com"
	echo 1>&2 ""
	echo 1>&2 "This script does not delete databases automatically (yet, work is in progress)."
	exit 0
fi

# Reset argument position.
shift $((OPTIND-1)); OPTIND=1

# Get web name (last argument).
OLD_WEB="$@"

# Check parameters.
if [ "$WEBS_DIR" = "" -o "$DRUPAL_VERSION" = "" -o "$DRUPAL_DIR" = "" -o "$OLD_WEB" = "" ]; then
	echo 1>&2 Usage: $0 -d /var/wwwlib -w /var/www -v 5 example.com
	exit 127
fi

# This is the complete path to the source Drupal folder.
# Remember that you must have a directory named "drupal-X" where X is its version (5 or 6) at $DRUPAL_DIR.
DRUPAL_BASE_DIR="$DRUPAL_DIR/drupal-$DRUPAL_VERSION"

# Sanity checks.
# Check if Drupal directory exists.
if [ ! -e $DRUPAL_BASE_DIR ]; then
	echo "Oops! Drupal base directory $DRUPAL_BASE_DIR does not exist. Aborting."
	exit 127
fi

# Check if web directory already exists.
if [ ! -e $WEBS_DIR/$OLD_WEB ]; then
	echo "Oops! Directory $WEBS_DIR/$OLD_WEB does not exist. Aborting."
	exit 127
fi

# Check if link or directory exists inside Drupal's sites folder and get rid of it if it does.
if [ -e $DRUPAL_BASE_DIR/sites/$OLD_WEB ]; then
	rm $DRUPAL_BASE_DIR/sites/$OLD_WEB
	echo "Symlink $DRUPAL_BASE_DIR/sites/$OLD_WEB deleted"
fi

# Remove folder if requested by user.
if [ "$REMOVE_FOLDER" = "TRUE" ]; then
	# Do a backup unless the users said not to.
	if [ ! "$NO_BACKUP" = "TRUE" ]; then
		echo "Backing up data..."
		tar zcf $BACKUP_DIR/$OLD_WEB`date +_%Y%m%d%H%M`_backup.tar.gz -C $WEBS_DIR $OLD_WEB
		echo "Backed up data to $WEBS_DIR/$OLD_WEB`date +_%Y%m%d%H%M`_backup.tar.gz"
	else
		echo "-N option specified. Data will not be backed up."
	fi
	# Delete the folder and all its contents.
	echo "Deleting web files..."
	rm -R $WEBS_DIR/$OLD_WEB
	echo "Directory $WEBS_DIR/$OLD_WEB deleted"
fi

echo
echo "All done."
echo

exit 0
