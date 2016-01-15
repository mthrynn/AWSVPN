#!/bin/bash
#**************************************************************
# TESTED PLATFORM: Mac OSX
# DESCRIPTION: script to terminate an instance on ec2. rebooted from
# sebsto/AWSVPN. This script to be a little more universal so that one can
# terminate any server that was created by the corresponding start script
# -- or any running instance on ec2 where the instance id is known
# NAME: ec2-terminate-instance
# AUTHOR: Drew Anderson
# VER: 0.1
# USAGE: ./USAGE: ec2-start-instance </path/to/cli-input-json-file>
# NOTES:
# you can echo the instance id to a file and use it to run this script
#
#
# set -n # Uncomment this to check script syntax without breaking things
 set -x # Uncomment this to debug
 #************************************************************

if [ -z "$1" ]  # test for the id file
then
  echo "Please provide the path to your instance id file:"
  read file
else
  file="$1"
fi

INSTANCE_FILE=$file

if [ ! -e $INSTANCE_FILE ]
then
    echo Missing $INSTANCE_FILE file
    exit -1
fi

echo "Terminating Instance..."
INSTANCE_ID=`cat $INSTANCE_FILE`

if [ -z $INSTANCE_ID ]
then
    echo Missing instance ID in $INSTANCE_FILE
    exit -1
fi

aws ec2 terminate-instances --instance-ids $INSTANCE_ID
rm $INSTANCE_FILE
