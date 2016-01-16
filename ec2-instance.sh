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

if [ -z "$1" ]  # test for the action
then
   echo "Please provide your desired action:"
   read action
else
   action="$1"
fi
if [ -z "$2" ]  # test for the cli-input-json file
then
   echo "Please provide your file base name (without extension):"
   read file
else
   file="$2"
fi

TAG_FILE=`echo $file | cut -d\. -f1`.tag.json
RUN_FILE=`echo $file | cut -d\. -f1`.json
ID_FILE=`echo $file | cut -d\. -f1`.id
NAME=`echo $file | cut -d\. -f1`

start_instance() {
	echo "Starting Instance..."
	INSTANCE_DETAILS=`aws ec2 run-instances --cli-input-json file://$RUN_FILE --output text | grep INSTANCES`

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
	aws ec2 create-tags --resources $INSTANCE_ID --cli-input-json file://$TAG_FILE

	echo "Instance started"

	echo "Instance ID = " $INSTANCE_ID
	DNS_NAME=`aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text | grep INSTANCES | awk '{print $15}'`
	AVAILABILITY_ZONE=`aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text | grep PLACEMENT | awk '{print $2}'`
	echo "DNS = " $DNS_NAME " in availability zone " $AVAILABILITY_ZONE
}

find_instance_id(){

	INSTANCE_FILE=$ID_FILE

	if [ ! -e $INSTANCE_FILE ]
	then
	    echo Missing $INSTANCE_FILE file
	    exit -1
	fi

	INSTANCE_ID=`cat $INSTANCE_FILE`

	if [ -z $INSTANCE_ID ]
	then
	    echo Missing instance ID in $INSTANCE_FILE
	    exit -1
	fi
}

terminate_instance() {

	find_instance_id
	echo "Terminating Instance"
	aws ec2 terminate-instances --instance-ids $INSTANCE_ID
	rm $INSTANCE_FILE
}

find_ip() {

   find_instance_id

   aws ec2 describe-instances --instance-ids i-4ae64ac3 --output text |grep ASSOCIATION | awk '{print $3 }' |uniq	
}

case "$action" in
        start) start_instance
           ;;
        term) terminate_instance
           ;;
        ip) find_ip
            ;;
        help) echo "Usage: ec2-instance.sh [start|term|ip] <basename of config files> "
             ;;
        *) echo " Invalid parameter"
           ;;
esac