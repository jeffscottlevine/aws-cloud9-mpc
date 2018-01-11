#!/bin/bash

# This script sets up the environment for the mpc (MyPollingCompany) demo
# on an AWS Cloud9 instance runnng Amazon Linux 1.
#
# The MyPollingCompany demo is an implementation of the Django tutorial
# at http://www.djangoproject.com. I wrote this so I could play with
# Django under AWS Cloud9.
#
# The script does the following:
#
# - Installs mysql-devel which is needed for Django
# - Installs pwgen to generate passwords
# - Installs jq to help determine the instance region
# - Installs an AWS Cloud9 "runner."
# - Starts mysqld
# - Generates password for the MySQL root user
# - Generates password for the MySQL mpc user
# - Does some basic MySQL security configuration
# - Sets up the mpc database
# - Sets up a python3 virtual environment
# - Initializes Django
#
# Security notes:
#
# - The set up is not strong and is only meant for a short lived demo.
# - The quality of passwords and keys is not that strong.
# - Passwords are used on comamand lines which is not advisable.
#
# Artifacts:
#
# MPC_DJANGO_ENV - file used to hold configuration info that
# will be supplied to Django.
#
# MYSQL_ROOT_PASSWORD - file that holds the MySQL root user password
# in case things get messed up.

# The mpc configuration file
MPC_DJANGO_ENV=./.env

# The file in which to store the MySQL root password in case of issues
MYSQL_ROOT_PASSWORD_FILE=$HOME/MYSQL_ROOT_PASSWORD

# The number of seconds to sleep at various points in the script.
# This is useful in catching errors.  Set this to at least 2.
SLEEP_TIME=2

# Directory for runners
RUNNER_DIR=../.c9/runners

echo checking for Amazon Linux version 1...
KERNEL_RELEASE=`uname -r`
I=`expr index "$KERNEL_RELEASE" amzn1`
if [ $I -eq 0 ]
then
    echo The operating system is not Amazon Linux 1.
    exit 1
fi
sleep $SLEEP_TIME

echo checking for presence of AWS Cloud9...
if [ ! -L $HOME/.c9 ]
then
    echo This does not appear to be an AWS Cloud 9 EC2 instance.
    exit 1
fi
sleep $SLEEP_TIME

echo installing mysql-develm pwgen, and jq...
sudo yum install -y -q mysql-devel pwgen jq
if [ $? -ne 0 ]
then
    echo Unable to install pacakges.
    exit 1
fi
sleep $SLEEP_TIME

echo generating MySQL root password...
MYSQL_ROOT_PASSWORD=`pwgen 8 1`
echo $MYSQL_ROOT_PASSWORD > $HOME/MYSQL_ROOT_PASSWORD
sleep $SLEEP_TIME

echo generating MySQL mpcuser password...
MYSQL_MPCUSER_PASSWORD=`pwgen 8 1`
sleep $SLEEP_TIME

echo generating Django superuser password...
DJANGO_SUPERUSER_PASSWORD=`pwgen 8 1`
echo $DJANGO_SUPERUSER_PASSWORD > $HOME/DJANGO_SUPERUSER_PASSWORD
sleep $SLEEP_TIME

echo generating Django secret key...
DJANGO_SECRET_KEY=`pwgen -s 50 1`
sleep $SLEEP_TIME

echo copying runner...
mkdir -p -m 755 $RUNNER_DIR
cp Django.run $RUNNER_DIR
chmod 644 $RUNNER_DIR/Django.run

echo determining region...
AWS_REGION=`curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region`
sleep $SLEEP_TIME

echo getting ready to start mysqld...
echo note: ignore messages about secure-file-priv, booting, and passwords...
sleep $SLEEP_TIME

echo starting mysqld...
sudo service mysqld start
if [ $? -ne 0 ]
then
    echo Unable to start mysqld.
    exit 1
fi
sleep $SLEEP_TIME

echo setting MySQL root password...
mysql -u root \
-e "UPDATE mysql.user SET Password=PASSWORD('$MYSQL_ROOT_PASSWORD') WHERE User='root';"
sleep $SLEEP_TIME

echo disabling MySQL remote root login...
mysql -u root \
-e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
sleep $SLEEP_TIME

echo removing anonymous MySQL users...
mysql -u root \
-e "DELETE FROM mysql.user WHERE User='';"
sleep $SLEEP_TIME

echo dropping test MySQL database...
mysql -u root \
-e "DROP DATABASE test;"
sleep $SLEEP_TIME

echo flushing MySQL privileges...
mysql -u root \
-e "FLUSH PRIVILEGES;"
sleep $SLEEP_TIME

echo creating mpc database...
mysql -u root -p$MYSQL_ROOT_PASSWORD \
-e "CREATE DATABASE mpc character set UTF8;"
sleep $SLEEP_TIME

echo creating mpcuser...
mysql -u root -p$MYSQL_ROOT_PASSWORD \
-e "CREATE USER mpcuser@localhost identified by '$MYSQL_MPCUSER_PASSWORD';"
sleep $SLEEP_TIME

echo granting privileges on mpc database tabkes...
mysql -u root -p$MYSQL_ROOT_PASSWORD \
-e "GRANT ALL PRIVILEGES on mpc.* to mpcuser@localhost;"
sleep $SLEEP_TIME

echo enabling mysqld to start automatically at boot time...
sudo chkconfig mysqld on
sleep $SLEEP_TIME

echo creating mpc Django environment file...
echo "SECRET_KEY=$DJANGO_SECRET_KEY" > $MPC_DJANGO_ENV
echo "DEBUG=True" >> $MPC_DJANGO_ENV
echo "DB_NAME=mpc" >> $MPC_DJANGO_ENV
echo "DB_USER=mpcuser" >> $MPC_DJANGO_ENV
echo "DB_PASSWORD=$MYSQL_MPCUSER_PASSWORD" >> $MPC_DJANGO_ENV
echo "DB_HOST=localhost" >> $MPC_DJANGO_ENV
echo "TIME_ZONE=America/Los_Angeles" >> $MPC_DJANGO_ENV
echo "ALLOWED_DOMAIN=.cloud9.$AWS_REGION.amazonaws.com" >> $MPC_DJANGO_ENV
sleep $SLEEP_TIME

echo setting up Python environment...
unalias python 2>/dev/null
virtualenv --python=/usr/bin/python3 env
source env/bin/activate
sleep $SLEEP_TIME

echo install Python modules...
pip install -r requirements.txt
sleep $SLEEP_TIME

echo setting up Django database tables...
python manage.py migrate
sleep $SLEEP_TIME

echo creating Django superuser $USER...
echo "from django.contrib.auth.models import User; User.objects.create_superuser('$USER', '', '$DJANGO_SUPERUSER_PASSWORD')" | python manage.py shell
sleep $SLEEP_TIME

echo
echo Initial set up complete!
echo
echo See this file for the Django superuser password: $HOME/DJANGO_SUPERUSER_PASSWORD
echo See this file for the MySQL mpcuser password: $HOME/MYSQL_MPCUSER_PASSWORD
echo
echo Now do the following

echo 1.  Navigate to and open the file manage.py in a workspace tab.
echo 2.  From the menu, click Run with\-\>Django.
echo 3.  A message will appear with a link to click which brings up the app.
echo 4.  Select "Administration" and log in with user $USER and password $DJANGO_SUPERUSER_PASSWORD.
echo 5.  Set up any users, questions, and choices.
echo 6.  Select "View Site" from the Administration page to go to the homepage.
echo 7.  Select "Polls" and play around with the questions.
echo 8.  When you are done, delete the Cloud9 workspace to stop further AWS charges.
