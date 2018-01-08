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
# This is useful in catching errors.

SLEEP_TIME=1

echo checking for Amazon Linux version 1...
KERNEL_RELEASE=`uname -r`
I=`expr index "$KERNEL_RELEASE" amzn1`
if [ $I -eq 0 ]
then
    echo "The operating system is not Amazon Linux 1."
    exit 1
fi

if [ ! -L $HOME/.c9 ]
then
    echo "This does not appear to be an AWS Cloud 9 EC2 instance."
    exit 1
fi

echo "installing mysql-devel..."
sudo yum install -y -q mysql-devel
if [ $? -ne 0 ]
then
    echo "Unable to install mysql-devel."
    exit 1
fi
sleep 1

echo "installing pwgen..."
sudo yum install -y -q pwgen
if [ $? -ne 0 ]
then
    echo "Unable to install pwgen."
    exit 1
fi
sleep 1

echo "starting mysqld..."
sudo service mysqld start
if [ $? -ne 0 ]
then
    echo "Unable to start mysqld."
    exit 1
fi
sleep 1

echo "generating MySQL root password..."
MYSQL_ROOT_PASSWORD=`pwgen 8 1`
echo $MYSQL_ROOT_PASSWORD > $HOME/MYSQL_ROOT_PASSWORD
sleep 1

echo generating MySQL mpcuser password...
MYSQL_MPCUSER_PASSWORD=`pwgen 8 1`
sleep 1

echo generating Django secret key...
DJANGO_SECRET_KEY=`pwgen -s 50 1`
sleep 1

echo "setting MySQL root password..."
mysql -u root \
-e "UPDATE mysql.user SET Password=PASSWORD('$MYSQL_ROOT_PASSWORD') WHERE User='root';"
sleep 1

echo "disabling MySQL remote root login..."
mysql -u root \
-e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
sleep 1

echo "removing anonymous MySQL users..."
mysql -u root \
-e "DELETE FROM mysql.user WHERE User='';"
sleep 1

echo "dropping test MySQL database..."
mysql -u root \
-e "DROP DATABASE test;"
sleep 1

echo "flushing MySQL privileges..."
mysql -u root \
-e "FLUSH PRIVILEGES;"
sleep 1

echo "creating mpc database..."
mysql -u root -p$MYSQL_ROOT_PASSWORD \
-e "CREATE DATABASE mpc character set UTF8;"
sleep 1

echo "creating mpcuser..."
mysql -u root -p$MYSQL_ROOT_PASSWORD \
-e "CREATE USER mpcuser@localhost identified by '$MYSQL_MPCUSER_PASSWORD';"
sleep 1

echo "granting privileges on mpc database tabkes..."
mysql -u root -p$MYSQL_ROOT_PASSWORD \
-e "GRANT ALL PRIVILEGES on mpc.* to mpcuser@localhost;"
sleep 1

echo "enabling mysqld to start automatically at boot time..."
sudo chkconfig mysqld on
sleep 1

echo "creating mpc Django environment file..."
echo "SECRET_KEY=$DJANGO_SECRET_KEY" > $MPC_DJANGO_ENV
echo "DEBUG=True" >> $MPC_DJANGO_ENV
echo "DB_NAME=mpc" >> $MPC_DJANGO_ENV
echo "DB_USER=mpcuser" >> $MPC_DJANGO_ENV
echo "DB_PASSWORD=$MYSQL_MPCUSER_PASSWORD" >> $MPC_DJANGO_ENV
echo "DB_HOST=localhost" >> $MPC_DJANGO_ENV
echo "TIME_ZONE=America/Los_Angeles" >> $MPC_DJANGO_ENV
sleep 1

echo setting up Python environment...
unalias python 2>/dev/null
virtualenv --python=/usr/bin/python3 env
source env/bin/activate
sleep 1

echo install Python modules...
pip install -r requirements.txt
sleep 1

echo setting up Django database tables...
python manage.py migrate
sleep 1

echo
echo Initial set up complete!
echo
echo Now do the following

echo 1. unalias python
echo 2. source env/bin/activate
echo 3. python manage.py createsuperuser
echo 4. python manage.py runserver 0:8080 
echo 5. browse to the appropriate URL:8080/admin/
echo 6. set up any users, questions, and choices
echo 7. browe to the appropriate URL:8080/polls/
echo 8. play around with the polls
