#!/bin/sh
#
# DMSAK - Drupal Multi-Site Admin Kit
# This script installs a Drupal codebase.
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
#
# install-drupal.sh - Installs a new Drupal code base.
#
#     Usage: install-drupal.sh [-d <path-to-drupal-dirs>] [-v N] <path-to-drupal-tarball>
#
#   Example: install-drupal.sh -d /var/lib -v 6 drupal-6.10.tar.gz
# Or simply: install-drupal.sh drupal-6.10.tar.gz
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
while getopts "d:v:h" flag
do
	case $flag in
		d)
			DRUPAL_DIR="$OPTARG"
			;;
		v)
			DRUPAL_VERSION="$OPTARG"
			;;
		h)
			HELP_REQUESTED="TRUE"
	esac
done

# Check if help was requested.
if [ "$HELP_REQUESTED" = "TRUE" ]; then
	echo 1>&2 "This script installs a Drupal code base"
	echo 1>&2 "Copyright 2009 by António Maria Torre do Valle"
	echo 1>&2 "Released under the GNU General Public Licence (GPL)"
	echo 1>&2 "More info at: http://www.torvall.net"
	echo 1>&2 ""
	echo 1>&2 "Usage: $0 [-d <path-to-drupal-dirs>] [-v N] <path-to-drupal-tarball>"
	echo 1>&2 ""
	echo 1>&2 "Parameters:"
	echo 1>&2 "  -h  Shows this help message"
	echo 1>&2 "  -d  Location of base Drupal directories (default: $DRUPAL_DIR)"
	echo 1>&2 "  -v  Drupal version to use (5, 6 or 7 others still untested) (default: $DRUPAL_VERSION)"
	echo 1>&2 "  <path-to-drupal-tarball> is the path to the Drupal code base to be installed (ex: drupal-6.10.tar.gz)"
	echo 1>&2 "  Parameters -d and -v are optional. See the config file (dmsak.cfg) to set the defaults."
	echo 1>&2 ""
	echo 1>&2 "Example: $0 -d /var/lib -v 6 drupal-6.10.tar.gz"
	exit 0
fi

# Reset argument position.
shift $((OPTIND-1)); OPTIND=1

# Get web name (last argument).
DRUPAL_TARBALL="$@"

# Check parameters.
if [ "$WEBS_DIR" = "" -o "$DRUPAL_DIR" = "" -o "$DRUPAL_VERSION" = "" -o "$DRUPAL_TARBALL" = "" ]; then
	echo 1>&2 Usage: $0 -d /var/lib -v 6 drupal-6.10.tar.gz
	exit 127
fi

# This is the complete path to the source Drupal folder.
# Remember that you must have a directory named "drupal-X" where X is its version (5 or 6) at $DRUPAL_DIR.
DRUPAL_BASE_DIR="$DRUPAL_DIR/drupal-$DRUPAL_VERSION"

DRUPAL_TARBALL_NAME=`basename $DRUPAL_TARBALL`
NEW_DRUPAL_TMP="$TEMP_DIR/${DRUPAL_TARBALL_NAME%.tar.gz}"

# Sanity checks.
# Check if install directory exists.
if [ ! -e $DRUPAL_DIR ]; then
	echo "Oops! Install directory $DRUPAL_DIR does not exist. Aborting."
	exit 127
fi

# Check if Drupal is already installed.
if [ -e $DRUPAL_BASE_DIR ]; then
	echo "Oops! Directory $DRUPAL_BASE_DIR already exists. Aborting."
	exit 127
fi

# Extract new package to $TEMP_DIR.
echo "Extracting $DRUPAL_TARBALL..."
tar zxf $DRUPAL_TARBALL -C $TEMP_DIR
echo "Tarball extracted to $NEW_DRUPAL_TMP."

# Create default folders.
if [ $DRUPAL_VERSION -le "6" ] ; then
	echo "Creating default folders..."
	mkdir $NEW_DRUPAL_TMP/sites/all/modules
	mkdir $NEW_DRUPAL_TMP/sites/all/themes
	echo "Default folders created."
fi

# Install new codebase.
echo "Moving new install to $DRUPAL_BASE_DIR..."
mv $NEW_DRUPAL_TMP $DRUPAL_BASE_DIR
echo "All done."

exit 0


