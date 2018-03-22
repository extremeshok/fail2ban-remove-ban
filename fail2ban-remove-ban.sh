#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Fail2ban IP Remove Ban / Unban Script
# Version 3.0
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
# Note: Script will expand CIDR addresses, eg 192.168.0.1/24
#
####################

if [ "$(which fail2ban-client 2> /dev/null)" == "" ]; then
  echo "ERROR: fail2ban-client was not found"
  exit 1
fi

### FUNCTIONS #################
prefix_to_bit_netmask() {
  prefix=$1;
  bitmask=""
  for (( i=0; i < 32; i++ )); do
    num=0
    if [ $i -lt "$prefix" ]; then
      num=1
    fi
    space=
    if [ $(( i % 8 )) -eq 0 ]; then
      space=" ";
    fi
    bitmask="${bitmask}${space}${num}"
  done
  echo "$bitmask"
}

bit_netmask_to_wildcard_netmask() {
  bitmask=$1;
  wildcard_mask=
  for octet in $bitmask; do
    wildcard_mask="${wildcard_mask} $(( 255 - 2#$octet ))"
  done
  echo "$wildcard_mask";
}

check_net_boundary() {
  net=$1;
  wildcard_mask=$2;
  is_correct=1;
  for (( i = 1; i <= 4; i++ )); do
    net_octet=$(echo "$net" | cut -d '.' -f $i)
    mask_octet=$(echo "$wildcard_mask" | cut -d ' ' -f $i)
    if [ "$mask_octet" -gt 0 ]; then
      if [ $(( net_octet&mask_octet )) -ne 0 ]; then
        is_correct=0;
      fi
    fi
  done
  echo $is_correct;
}

function xshok_unban_from_jails() { #ipaddress
  ipaddress="$1";
  for f2bjail in $f2bjails_array ; do
    result="$(fail2ban-client set "$f2bjail" unbanip "$ipaddress" 2>&1)"
    if [[ "$result" != *"NOK"* ]]; then
      echo "Removed $ipaddress ban from $f2bjail"
    fi
  done
}
### MAIN #################

# Defaults
script_name=${0##*/}

if ! fail2ban-client status 2> /dev/null ; then
  echo "ERROR: No fail2ban Jails found, is fail2ban running and are you root"
  exit 1
fi

# Get the Fail2ban Jails
f2bjails_array="$(fail2ban-client status 2> /dev/null | grep "Jail list" | sed -E 's/^[^:]+:[ \t]+//' | sed 's/,//g')"


OPTIND=1;
getopts "fibh" force;

shift $((OPTIND-1))
if [ "$force" = 'h' ] ; then
  echo ""
  echo "This will  also expand CIDR addresses"
  echo "$script_name [OPTION(only one)] [STRING/FILENAME]"
  echo "DESCRIPTION"
  echo "-h  Displays this help screen"
  echo "-f  Forces a check for network boundary when given a STRING(s)"
  echo "-i  Will read from an Input file (no network boundary check)"
  echo "-b  Will do the same as –i but with network boundary check"
  echo "EXAMPLES"
  echo "$script_name 192.168.0.1"
  echo "$script_name 192.168.0.1/24 10.10.0.0"
  echo "$script_name -f 192.168.0.0/16"
  echo "$script_name -i inputfile.txt"
  echo "$script_name -b inputfile.txt"
  exit
fi

if [ "$force" = 'i' ] || [ "$force" = 'b' ] ; then
  old_IPS=$IPS
  IPS=$'\n'
  #ip_array=( $(cat "$1") ) # array
  IFS=" " read -r -a ip_array <<< "$(mycommand)"
  IPS=$old_IPS
else
  ip_array=( "$@" )
fi


echo "Removing bans from the following Jails for ${ip_array[*]}"
echo "$f2bjails_array"

for ip in "${ip_array[@]}" ; do
  if [[ ! "$ip" =~ "/" ]] ; then
    #single ip
    xshok_unban_from_jails "$ip"
  else
    #ip range
    net=$(echo "$ip" | cut -d '/' -f 1);
    prefix=$(echo "$ip" | cut -d '/' -f 2);
    do_processing=1;

    bit_netmask=$(prefix_to_bit_netmask "$prefix");

    wildcard_mask=$(bit_netmask_to_wildcard_netmask "$bit_netmask");
    is_net_boundary=$(check_net_boundary "$net" "$wildcard_mask");

    if [ "$force" == "f" ] && [ "$is_net_boundary" -ne 1 ] || [ "$force" == "b" ] && [ "$is_net_boundary" -ne 1 ] ; then
      read -p "Not a network boundary! Continue anyway (y/N)? " -n 1 -r
      echo    ## move to a new line
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        do_processing=1;
      else
        do_processing=0;
      fi
    fi

    if [ $do_processing -eq 1 ] ; then
      str=""
      for (( i = 1; i <= 4; i++ )) ; do
        range=$(echo "$net" | cut -d '.' -f $i)
        mask_octet=$(echo "$wildcard_mask" | cut -d ' ' -f $i)
        if [ "$mask_octet" -gt 0 ] ; then
          range="{$range..$(( "$range" | "$mask_octet" ))}";
        fi
        str="${str} $range"
      done
      #ips=$(echo "$str" | sed "s, ,\\.,g"); ## replace spaces with periods, a join...
      ips="${str// /\.}" ## replace spaces with periods, a join...
      ip_array2="$(eval echo "$ips" | tr ' ' '\n')"

      for ip2 in "${ip_array2[@]}" ; do
        echo "Checking: $ip2"
        xshok_unban_from_jails "$ip2"
      done
    else
      exit
    fi
  fi
done
