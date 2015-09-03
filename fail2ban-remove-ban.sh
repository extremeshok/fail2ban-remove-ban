#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Fail2ban IP Remove Ban / Unban Script
# Version 1.0
# 03 September 2015
# Copyright (c) Adrian Jon Kriel : root-at-extremecooling-dot-org
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
####################
#
# Remove Ban / Unban an IP from all Fail2ban Jails
#
####################

if [[ ! "$1" ]]; then
    echo "Usage: ${0##*/} <ip-address-to-unban>";
	exit
fi

if [[ ! $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "ERROR: invalid IP $1";
	exit
fi

JAILS=`fail2ban-client status | grep "Jail list" | sed -E 's/^[^:]+:[ \t]+//' | sed 's/,//g'`
for JAIL in $JAILS
do
  RESULT=`fail2ban-client set $JAIL unbanip 196.210.84.111 2>&1`

  if [[ "$RESULT" == *"NOK"* ]]; then
    echo "IP NOT banned in $JAIL";
  else
     echo "Removed IP ban from $JAIL"
  fi
done