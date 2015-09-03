#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Fail2ban IP Remove Ban / Unban Script
# Version 2.0
# 03 September 2015
# Copyright (c) Adrian Jon Kriel : root-at-extremecooling-dot-org
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
####################
#
# Remove Ban / Unban an IP from all Fail2ban Jails
# Usage: fail2ban-remove-ban.sh <ip-address-to-unban>
#
# Remove Ban of multiple IP addresses
# Usage: fail2ban-remove-ban.sh <ip-1> <ip-2> <ip-3>
#
####################
if [[ ! "$1" ]]; then
    echo "Usage: ${0##*/} <ip-address-to-unban>";
    echo "Multiple IP: ${0##*/} <ip1> <ip2> <ip3> <ip4>";
	exit
fi

for var in "$@"
do
	if [[ $var =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	    JAILS=`fail2ban-client status | grep "Jail list" | sed -E 's/^[^:]+:[ \t]+//' | sed 's/,//g'`
		for JAIL in $JAILS
		do
		  RESULT=`fail2ban-client set $JAIL unbanip $var 2>&1`

		  if [[ "$RESULT" == *"NOK"* ]]; then
		    echo "$var NOT banned in $JAIL";
		  else
		     echo "Removed $var ban from $JAIL"
		  fi
		done
	else
		echo "ERROR: invalid IP $var";

	fi
done

