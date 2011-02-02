#!/bin/sh
#
# DMSAK - Drupal Multi-Site Admin Kit
# This script creates a Drupal "secure virtual folder".
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
#     Usage: mkweb.sh [-d <path-to-drupal-dirs>] [-w <path-to-webs-dir>] [-v N] <website>
#
#   Example: mkweb.sh -d /var/wwwlib -w /var/www -v 5 example.com
# Or simply: mkweb.sh example.com
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
while getopts "d:w:v:sh" flag
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
		s)
			SHORT_FILES_URLS="TRUE"
			;;
		h)
			HELP_REQUESTED="TRUE"
	esac
done

# Check if help was requested.
if [ "$HELP_REQUESTED" = "TRUE" ]; then
	echo 1>&2 "This script creates a Drupal \"secure virtual folder\""
	echo 1>&2 "Copyright 2009 by António Maria Torre do Valle"
	echo 1>&2 "Released under the GNU General Public Licence (GPL)"
	echo 1>&2 "More info at: http://www.torvall.net"
	echo 1>&2 ""
	echo 1>&2 "Usage: $0 [-d <path-to-drupal-dirs>] [-w <path-to-webs-dir>] [-v N] <website>"
	echo 1>&2 ""
	echo 1>&2 "Parameters:"
	echo 1>&2 "  -h  Shows this help message"
	echo 1>&2 "  -d  Location of base Drupal directories (default: $WEBS_DIR)"
	echo 1>&2 "  -w  Directory where site is to be created at (default: $DRUPAL_DIR)"
	echo 1>&2 "  -v  Drupal version to use (5 or 6, others still untested) (default: $DRUPAL_VERSION)"
	echo 1>&2 "  -s  Enable short 'files' URLs (EXPERIMENTAL FEATURE)"
	echo 1>&2 "  <website> is the domain name of the website to be created (ex: example.com)"
	echo 1>&2 "  Parameters -d, -w and -v are optional. See the config file (dmsak.cfg) to set the defaults."
	echo 1>&2 ""
	echo 1>&2 "Example: $0 -d /var/wwwlib -w /var/www -v 5 example.com"
	echo 1>&2 ""
	echo 1>&2 "This script does not create databases automatically (yet, work is in progress)."
	exit 0
fi

# Reset argument position.
shift $((OPTIND-1)); OPTIND=1

# Get web name (last argument).
NEW_WEB="$@"

# Check parameters.
if [ "$WEBS_DIR" = "" -o "$DRUPAL_VERSION" = "" -o "$DRUPAL_DIR" = "" -o "$NEW_WEB" = "" ]; then
	echo 1>&2 Usage: $0 -d /var/wwwlib -w /var/www -v 5 example.com
	exit 127
fi

# This is the complete path to the source Drupal folder.
# Remember that you must have a directory named "drupal-X" where X is its version (5 or 6) at $DRUPAL_DIR.
DRUPAL_BASE_DIR="$DRUPAL_DIR/drupal-$DRUPAL_VERSION"

# Get the default settings.php file according to version.
if [ $DRUPAL_VERSION -ge "6" ] ; then
	SETTINGS_FILE=$DRUPAL_BASE_DIR/sites/default/default.settings.php
else
	SETTINGS_FILE=$DRUPAL_BASE_DIR/sites/default/settings.php
fi

# Sanity checks.
# Check if Drupal directory exists.
if [ ! -e $DRUPAL_BASE_DIR ]; then
	echo "Oops! Drupal directory $DRUPAL_BASE_DIR does not exist. Aborting."
	exit 127
fi

# Check if web directory already exists.
if [ -e $WEBS_DIR/$NEW_WEB ]; then
	echo "Oops! Directory $WEBS_DIR/$NEW_WEB already exists. Aborting."
	exit 127
fi

# Check if link or directory already exists inside Drupal's sites folder.
if [ -e $DRUPAL_BASE_DIR/sites/$NEW_WEB ]; then
	echo "Oops! Link or directory $DRUPAL_BASE_DIR/sites/$NEW_WEB already exists. Aborting."
	exit 127
fi

# Check if settings.php is present (also serves as a test for the sites folder).
if [ ! -e $SETTINGS_FILE ]; then
	echo "Oops! Default settings.php file not found at $SETTINGS_FILE. Aborting."
	exit 127
fi

# Create the base folder structure for the specified vdir.
mkdir $WEBS_DIR/$NEW_WEB
mkdir $WEBS_DIR/$NEW_WEB/sites
mkdir $WEBS_DIR/$NEW_WEB/sites/$NEW_WEB
mkdir $WEBS_DIR/$NEW_WEB/sites/$NEW_WEB/modules
mkdir $WEBS_DIR/$NEW_WEB/sites/$NEW_WEB/themes


# Link the newly created sites/$NEW_WEB directory from Drupal's sites dir.
ln -s $WEBS_DIR/$NEW_WEB/sites/$NEW_WEB $DRUPAL_BASE_DIR/sites/$NEW_WEB

# Link to the sites/all dir in Drupal's folder.
ln -s $DRUPAL_BASE_DIR/sites/all $WEBS_DIR/$NEW_WEB/sites/all

# These files are to specify different permissions per site.
cp $DRUPAL_BASE_DIR/.htaccess  $WEBS_DIR/$NEW_WEB/
cp $DRUPAL_BASE_DIR/robots.txt $WEBS_DIR/$NEW_WEB/

# Short "files" URLs. (EXPERIMENTAL FEATURE!!!)
if [ "$SHORT_FILES_URLS" = "TRUE" ]; then
	# Create the "root" files folder.
	mkdir $WEBS_DIR/$NEW_WEB/files
	# Make it writable. (Is this really needed?)
	chmod o+w $WEBS_DIR/$NEW_WEB/files
	# Add rewrite rule to .htaccess to wrap requests to correct files dir path.
	echo >> $WEBS_DIR/$NEW_WEB/files/.htaccess
	echo "RewriteCond %{REQUEST_FILENAME} !-f" >> $WEBS_DIR/$NEW_WEB/files/.htaccess
	echo "RewriteCond %{REQUEST_FILENAME} !-d" >> $WEBS_DIR/$NEW_WEB/files/.htaccess
	echo "RewriteRule ^(.*)$ /sites/$NEW_WEB/files/\$1 [L]" >> $WEBS_DIR/$NEW_WEB/files/.htaccess
else
	# Create the standard example.com/sites/example.com/files folder.
	mkdir $WEBS_DIR/$NEW_WEB/sites/$NEW_WEB/files
	# Make the files folder writable.
	chmod o+w $WEBS_DIR/$NEW_WEB/sites/$NEW_WEB/files
fi

# Copy the default settings.php file.
cp $SETTINGS_FILE $WEBS_DIR/$NEW_WEB/sites/$NEW_WEB/settings.php

# Remove the read only restriction from settings.php.
chmod o+w $WEBS_DIR/$NEW_WEB/sites/$NEW_WEB/settings.php

# Append some required configuration variables to settings.php.
# Uncomment the following line to let this script setup the file system configuration options automatically for you.
#echo "\$conf = array('file_directory_path' => 'sites/$NEW_WEB/files', 'file_directory_temp' => '$TEMP_DIR');" >> $WEBS_DIR/$NEW_WEB/sites/$NEW_WEB/settings.php

# Link to the required folders inside Drupal's directory.
ln -s $DRUPAL_BASE_DIR/misc $WEBS_DIR/$NEW_WEB/misc
ln -s $DRUPAL_BASE_DIR/modules $WEBS_DIR/$NEW_WEB/modules
ln -s $DRUPAL_BASE_DIR/themes $WEBS_DIR/$NEW_WEB/themes

# Create the wrappers to handle requests.
echo "<?php chdir('$DRUPAL_BASE_DIR'); include('./index.php'); ?>" > $WEBS_DIR/$NEW_WEB/index.php
echo "<?php chdir('$DRUPAL_BASE_DIR'); include('./cron.php'); ?>" > $WEBS_DIR/$NEW_WEB/cron.php
echo "<?php chdir('$DRUPAL_BASE_DIR'); include('./update.php'); ?>" > $WEBS_DIR/$NEW_WEB/update.php
echo "<?php chdir('$DRUPAL_BASE_DIR'); include('./xmlrpc.php'); ?>" > $WEBS_DIR/$NEW_WEB/xmlrpc.php
echo "<?php chdir('$DRUPAL_BASE_DIR'); include('./install.php'); ?>" > $WEBS_DIR/$NEW_WEB/install.php

# Enter DB creation stage.
DB_NAME=${NEW_WEB//./_}
echo "Creating database $DB_NAME..."

# Get database password interactively if not specified in config.
if [ "$DB_PASS" = "" ]; then
	read -s -p "Enter $DB_USER's database password: " TEMP_PASS
	DB_PASS=${TEMP_PASS}
	echo
fi

# Create database.
mysqladmin --host=$DB_HOST --user=$DB_USER --password=$DB_PASS create $DB_NAME
echo "Database $DB_NAME created."

# Grant permissions to user on the database.
SQL_CMD="GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON $DB_NAME.* TO $DB_USER@$DB_HOST IDENTIFIED BY '$DB_PASS';"
mysql --silent --host=$DB_HOST --user=$DB_USER --password=$DB_PASS $DB_NAME << EOF
	$SQL_CMD
EOF
echo "Permissions set on database."

# Set the database configuration.
sed -i "s/mysql:\/\/username:password@localhost\/databasename/mysql:\/\/$DB_USER:$DB_PASS@$DB_HOST\/$DB_NAME/g" $WEBS_DIR/$NEW_WEB/sites/$NEW_WEB/settings.php
echo "Database config set on settings.php."

# Report success to the user.
echo "Created structure for site $NEW_WEB."

# Tell the user the next steps to take.
echo
echo "You should now edit the file $DRUPAL_BASE_DIR/sites/$NEW_WEB/settings.php to configure your new website."
echo "Then setup the vdir in Apache (if you haven't already) and browse to http://$NEW_WEB/install.php to finish the install."
echo "Don't forget to delete the install.php file after properly setting up Drupal:"
echo "  rm $WEBS_DIR/$NEW_WEB/install.php"
echo "...and to remove the write permissions from settings.php:"
echo "  chmod o-w $WEBS_DIR/$NEW_WEB/sites/$NEW_WEB/settings.php"
echo "Good luck!"
echo

exit 0
