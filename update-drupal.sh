#!/bin/sh
#
# DMSAK - Drupal Multi-Site Admin Kit
# This script updates a Drupal code base.
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
#     Usage: update-drupal.sh [-d <path-to-drupal-dirs>] [-v N] <path-to-drupal-tarball>
#
#   Example: update-drupal.sh -d /var/wwwlib -v 6 drupal-6.10.tar.gz
# Or simply: update-drupal.sh drupal-6.10.tar.gz
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
while getopts "d:v:Nh" flag
do
	case $flag in
		d)
			DRUPAL_DIR="$OPTARG"
			;;
		v)
			DRUPAL_VERSION="$OPTARG"
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
	echo 1>&2 "This script updates a Drupal code base"
	echo 1>&2 "Copyright 2009 by António Maria Torre do Valle"
	echo 1>&2 "Released under the GNU General Public Licence (GPL)"
	echo 1>&2 "More info at: http://www.torvall.net"
	echo 1>&2 ""
	echo 1>&2 "Usage: $0 [-d <path-to-drupal-dirs>] [-v N] <path-to-drupal-tarball>"
	echo 1>&2 ""
	echo 1>&2 "Parameters:"
	echo 1>&2 "  -h  Shows this help message"
	echo 1>&2 "  -d  Location of base Drupal directories (default: $DRUPAL_DIR)"
	echo 1>&2 "  -v  Drupal version to use (5, 6 or 7, others still untested) (default: $DRUPAL_VERSION)"
	echo 1>&2 "  -N  Do not backup folder before update"
	echo 1>&2 "  <path-to-drupal-tarball> is the path to the package that contains the version to be installed (ex: drupal-6.10.tar.gz)"
	echo 1>&2 "  Parameters -d and -v are optional. See the config file (dmsak.cfg) to set the defaults."
	echo 1>&2 ""
	echo 1>&2 "Example: $0 -v 6 drupal-6.10.tar.gz"
	exit 0
fi

# Reset argument position.
shift $((OPTIND-1)); OPTIND=1

# Get web name (last argument).
NEW_PACKAGE="$@"

# Check parameters.
if [ "$DRUPAL_VERSION" = "" -o "$DRUPAL_DIR" = "" -o "$NEW_PACKAGE" = "" ]; then
	echo 1>&2 Usage: $0 -d /var/lib -v 6 drupal-6.10.tar.gz
	exit 127
fi

# This is the complete path to the source Drupal folder.
# Remember that you must have a directory named "drupal-X" where X is its version (5 or 6) at $DRUPAL_DIR.
DRUPAL_BASE_DIR="$DRUPAL_DIR/drupal-$DRUPAL_VERSION"

DRUPAL_BACKUP_TARBALL=$BACKUP_DIR/drupal-$DRUPAL_VERSION-`date +%Y%m%d%H%M`-backup.tar.gz
NEW_PACKAGE_TARBALL=`basename $NEW_PACKAGE`
NEW_PACKAGE_TMP="$TEMP_DIR/${NEW_PACKAGE_TARBALL%.tar.gz}"

# Sanity checks.
# Check if Drupal directory exists.
if [ ! -e $DRUPAL_BASE_DIR ]; then
	echo "Oops! Drupal directory $DRUPAL_BASE_DIR does not exist. Aborting."
	exit 127
fi

# Create backup, unless user said otherwise.
if [ ! "$NO_BACKUP" = "TRUE" ]; then
	echo "Backing up existing drupal-$DRUPAL_VERSION..."
	tar zcf $DRUPAL_BACKUP_TARBALL -C $DRUPAL_DIR drupal-$DRUPAL_VERSION
	echo "Backed data up to $DRUPAL_BACKUP_TARBALL."
else
	echo "-N option specified. Data will not be backed up."
fi

# Extract new package to $TEMP_DIR.
echo "Extracting $NEW_PACKAGE_TARBALL..."
tar zxf $NEW_PACKAGE -C $TEMP_DIR
echo "Tarball extracted to $NEW_PACKAGE_TMP."

# Back up the new sites folder, just in case...
mv $NEW_PACKAGE_TMP/sites $NEW_PACKAGE_TMP/sites.bak

# Move the sites folder to the new codebase.
echo "Moving $DRUPAL_BASE_DIR/sites to new Drupal install tree..."
mv $DRUPAL_BASE_DIR/sites $NEW_PACKAGE_TMP
echo "Done."

# Remove old codebase.
echo "Deleting old Drupal dir..."
rm -R $DRUPAL_BASE_DIR
echo "$DRUPAL_BASE_DIR deleted."

# Install new codebase.
echo "Moving new install to final location..."
mv $NEW_PACKAGE_TMP $DRUPAL_BASE_DIR
echo "All done."
echo "Don't forget to update.php all sites that use version $DRUPAL_VERSION!"

exit 0

