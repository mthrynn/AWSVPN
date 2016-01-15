#!/bin/bash
#**************************************************************
# TESTED PLATFORM: Mac OSX
# DESCRIPTION: script to start an instance on ec2. rebooted from
# sebsto/AWSVPN. This script to be a little more universal so that one can
# provision any server just by creating a cli-input-json file and a provisioning
# script
# NAME: ec2-start-instance
# AUTHOR: Drew Anderson
# VER: 0.1
# USAGE: ./USAGE: ec2-start-instance </path/to/cli-input-json-file>
# NOTES:
#
#
#
# set -n # Uncomment this to check script syntax without breaking things
# set -x # Uncomment this to debug
#************************************************************

if [ -z "$1" ]  # test for the cli-input-json file
then
   echo "Please provide the path to your cli-input-json file:"
   read file
else
   file="$1"
fi
ID_FILE=`echo $file | cut -d\. -f1`.id
NAME=`echo $file | cut -d\. -f1`

echo "Starting Instance..."
INSTANCE_DETAILS=`aws ec2 run-instances --cli-input-json file://$file --output text | grep INSTANCES`

INSTANCE_ID=`echo $INSTANCE_DETAILS | awk '{print $7}'`
echo $INSTANCE_ID > $ID_FILE

# wait for instance to be started
STATUS=`aws ec2 describe-instance-status --instance-ids $INSTANCE_ID --output text | grep INSTANCESTATUS | grep -v INSTANCESTATUSES | awk '{print $2}'`

while [ "$STATUS" != "ok" ]
do
    printf "\r Waiting for instance to start...."
    sleep 5
    STATUS=`aws ec2 describe-instance-status --instance-ids $INSTANCE_ID --output text | grep INSTANCESTATUS | grep -v INSTANCESTATUSES | awk '{print $2}'`
done

echo "tag instances"
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=$NAME,Value=   Key=stack,Value=Production

echo "Instance started"

echo "Instance ID = " $INSTANCE_ID
DNS_NAME=`aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text | grep INSTANCES | awk '{print $15}'`
AVAILABILITY_ZONE=`aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text | grep PLACEMENT | awk '{print $2}'`
echo "DNS = " $DNS_NAME " in availability zone " $AVAILABILITY_ZONE
