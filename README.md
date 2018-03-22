# fail2ban-remove-ban
Remove Ban / Unban an IP from all Fail2ban Jails

## Usage
-h  Displays this help screen
-f  Forces a check for network boundary when given a STRING(s)
-i  Will read from an Input file (no network boundary check)
-b  Will do the same as –i but with network boundary check

## EXAMPLES
xshok_fail2ban_remove_ban.sh 192.168.0.1
xshok_fail2ban_remove_ban.sh 192.168.0.1/24 10.10.0.0
xshok_fail2ban_remove_ban.sh -f 192.168.0.0/16
xshok_fail2ban_remove_ban.sh -i inputfile.txt
xshok_fail2ban_remove_ban.sh -b inputfile.txt

