#!/bin/sh
#
# DMSAK - Drupal Multi-Site Admin Kit
# This script updates a Drupal theme.
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
#     Usage: uptheme.sh [-d <path-to-drupal-dirs> [-v X] | -w <path-to-web-dir>] [-N] <path-to-theme-tarball>
#
#   Example: uptheme.sh -d /var/wwwlib -v 5 -N theme-5.x-1.10.tar.gz
#        Or: uptheme.sh -w /var/www/example.com -v 5 -N theme-5.x-1.10.tar.gz
# Or simply: uptheme.sh theme-5.x-1.10.tar.gz
#
# This script assumes that Drupal folders are named "drupal-X" where X is the version number (5 or 6).
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
WEB_URL=""
while getopts "d:v:w:W:Nh" flag
do
	case $flag in
		d)
			DRUPAL_DIR="$OPTARG"
			;;
		v)
			DRUPAL_VERSION="$OPTARG"
			;;
		w)
			WEBS_DIR="$OPTARG"
			;;
		W)
			WEB_URL="$OPTARG"
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
	echo 1>&2 "This script updates a Drupal theme"
	echo 1>&2 "Copyright 2009 by António Maria Torre do Valle"
	echo 1>&2 "Released under the GNU General Public Licence (GPL)"
	echo 1>&2 "More info at: http://www.torvall.net"
	echo 1>&2 ""
	echo 1>&2 "Usage: $0 [-d <path-to-drupal-dirs>] [-w <path-to-web-dir>] [-v X] [-N] <path-to-theme-tarball>"
	echo 1>&2 "   Or: $0 [-N] [-W <website>] <path-to-theme-tarball>"
	echo 1>&2 ""
	echo 1>&2 "Parameters:"
	echo 1>&2 "  -h  Shows this help message"
	echo 1>&2 "  -d  Location of base Drupal directories (default: $DRUPAL_DIR)"
	echo 1>&2 "  -w  Directory containing websites (default: $WEBS_DIR)"
	echo 1>&2 "  -v  Drupal version (5 or 6, others still untested) (default: $DRUPAL_VERSION)"
	echo 1>&2 "  -W  Website to update (ex: example.com)"
	echo 1>&2 "  -N  Do not backup old theme folder"
	echo 1>&2 "  <path-to-theme-tarball> is the path to the package that contains the theme to be installed (ex: theme-5.x-1.10.tar.gz)"
	echo 1>&2 "  If the -W option is specified, parameters -d and -v will be ignored."
	echo 1>&2 "  Parameters -d, -w and -v are optional, and the configured values will be used. See the config file dmsak.cfg."
	echo 1>&2 ""
	echo 1>&2 "Example: $0 -d /var/wwwlib -w /var/www -v 5 -N theme-5.x-1.10.tar.gz"
	echo 1>&2 "     Or: $0 -W example.com -N theme-5.x-1.10.tar.gz"
	exit 0
fi

# Reset argument position.
shift $((OPTIND-1)); OPTIND=1

# Get new theme path (last argument).
NEW_THEME_PATH="$@"
NEW_THEME_FILENAME=`basename $NEW_THEME_PATH`
SEPARATOR_POSITION=$((`expr index "$NEW_THEME_FILENAME" "-"`-1))
THEME_NAME=`expr substr $NEW_THEME_FILENAME 1 $SEPARATOR_POSITION`

# Check command line parameters.
if [ "$WEB_URL" != "" ]; then
	# Check parameters to update theme in web dir.
	if [ "$WEBS_DIR" = "" -o "$NEW_THEME_PATH" = "" ]; then
		echo 1>&2 Usage: $0 -d /var/wwwlib -w /var/www -v 5 -N theme-5.x-1.10.tar.gz
		echo 1>&2    Or: $0 -W example.com -N theme-5.x-1.10.tar.gz
		exit 127
	fi

	# Get the target folder and some others.
	WEB_BASE_DIR="$WEBS_DIR/$WEB_URL"
	THEMES_DIR="$WEB_BASE_DIR/sites/$WEB_URL/themes"
	THEME_DIRECTORY="$THEMES_DIR/$THEME_NAME"

	# Sanity checks.
	# Check if web directory exists.
	if [ ! -e $WEB_BASE_DIR  ]; then
		echo "Oops! Web directory $WEB_BASE_DIR does not exist. Aborting."
		exit 127
	fi
else
	# Check parameters to update theme in Drupal code base dir.
	if [ "$DRUPAL_VERSION" = "" -o "$DRUPAL_DIR" = "" -o "$NEW_THEME_PATH" = "" ]; then
		echo 1>&2 Usage: $0 -d /var/wwwlib -w /var/www -v 5 -N theme-5.x-1.10.tar.gz
		echo 1>&2    Or: $0 -W example.com -N theme-5.x-1.10.tar.gz
		exit 127
	fi

	# Get the target folder and some others.
	DRUPAL_BASE_DIR="$DRUPAL_DIR/drupal-$DRUPAL_VERSION"
	THEMES_DIR=$DRUPAL_BASE_DIR/sites/all/themes
	THEME_DIRECTORY=$THEMES_DIR/$THEME_NAME

	# Sanity checks.
	# Check if Drupal directory exists.
	if [ ! -e $DRUPAL_BASE_DIR  ]; then
		echo "Oops! Drupal directory $DRUPAL_BASE_DIR does not exist. Aborting."
		exit 127
	fi
fi

# Check that the theme directory is there.
if [ ! -e $THEME_DIRECTORY  ]; then
	echo "Oops! Theme directory not present at $THEME_DIRECTORY. Aborting."
	exit 127
fi

# Backup data unless otherwise specified by user.
if [ ! "$NO_BACKUP" = "TRUE" ]; then
	THEME_BACKUP_TARBALL=$BACKUP_DIR/$THEME_NAME`date +_%Y%m%d%H%M`_backup.tar.gz
	echo "Backing up data..."
	tar zcf $THEME_BACKUP_TARBALL -C $THEMES_DIR $THEME_NAME
	echo "Backed up theme folder to $THEME_BACKUP_TARBALL."
else
	echo "-N option specified. Data will not be backed up."
fi

# Extract new package to $TEMP_DIR.
echo "Extracting $NEW_PACKAGE_TARBALL..."
tar zxf $NEW_THEME_PATH -C $TEMP_DIR
echo "Theme tarball extracted to $TEMP_DIR/$THEME_NAME."

# Delete old theme directory.
echo "Deleting old theme folder..."
rm -r $THEME_DIRECTORY
echo "$THEME_DIRECTORY deleted."

# Move new theme folder to destination.
echo "Moving new theme's directory to final destination..."
mv $TEMP_DIR/$THEME_NAME $THEMES_DIR
echo "Directory moved to $THEMES_DIR/$THEME_NAME."

# Display some form of success message to the user.
echo
echo "All done."
echo $SUCCESS_MESSAGE
echo

exit 0

