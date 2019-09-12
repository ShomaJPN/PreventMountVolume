#!/bin/bash
##
## ---This Ver is test-drive---
##
## Name:
##  PreventMountVolume.sh
##  Created by SHOMA on 9/13/2019. Last edited by SHOMA 9/13/2019
##
## Overview:
##  Prevent (control) mounting of external volumes, e.g. USB-thumb-drive.
##
## Discription:
##  This script is created to mount only allowed external volumes.
##  Simple imprementation because it uses launchd's StartOnMount trigger.
##
## Requirements:
##  -macOS
##  -Test under macOS 10.14.6
##
## Install and Run:
##  - Copy this script to the appropriate directory (ex.~/Script)
##    and set it Excutable.
##  - Use with launchd/lauchctl
##   - Make commnad-plist file and put it ~/Library/LaunchAgents/
##    - Start with the following command (only the first time)
##       launchctl load /Path/to/plist
##  　- Stop is ...
##       launchctl unload /Path/to/plist
##    - Stop forever...
##       Remove plist from ~/Library/LaunchAgents/ (e.g. rm command)
##    - Check is ...
##       　launchctl list
##  - A confirmation dialog (xxx would like to control "System Events"...)
##    appear at the first run, then allow it.  
##
## References:
##  If you did not confirm by mistake, try "$ tccutil reset AppleEvents"
##  If you want to apply to all users, put commnad-plist /Library/LaunchAgents/
##
##
## Author: SHOMA Shimahara <shoma@yk.rim.or.jp>
##





######################## Set "Log" file and function ###########################

LogPath=$HOME/log
LogFile="$LogPath/PreventMountVolume.log"

if [ ! -d "$LogPath" ]; then
    echo "Log directory is not exit!"
    mkdir $LogPath
    echo "Log directory is created"
  else
    echo "Log directory is exit!"
fi

function SendToLog ()
{
echo $(date +"%Y-%m-%d %T") : $@ | tee -a "$LogFile"
}

##################### End of set "Log" file and function #######################


WhiteList_Vol_UUID=""
WhiteList_Vol="disk5" #VolumeIdentifer

Startup_Vol=$(df / |grep ^/dev |cut -d' ' -f1)
Startup_Disk=$(echo $Startup_Vol |sed 's/s[0-9]*$//g')

echo "Startup Vol and Disk"
echo $Startup_Vol
echo $Startup_Disk


#List_of_Outer_Vol=$(df |grep ^/dev |cut -d' ' -f1)
List_of_Outer_Vol=$(df |grep ^/dev |cut -d' ' -f1 |grep -v "$Startup_Disk"s)

echo "---"
echo "List of Outer vol"
echo "$List_of_Outer_Vol"

echo "---"
echo "wo WhiteList"
echo "$List_of_Outer_Vol" |grep -v "$WhiteList_Vol"

List_of_Outer_Vol_WO_WLV=$(echo "$List_of_Outer_Vol" |grep -v "$WhiteList_Vol")

# for i in $List_of_Outer_Vol_WO_WLV
#     do
#         [[ $(diskutil info $i |grep Protocol |egrep "USB|FireWire|Thunderbolt") ]] &&
#         diskutil unmount $i
#         echo "Result is: " $?
#     done

for i in $List_of_Outer_Vol_WO_WLV
do
    [ "$(diskutil info $i |grep Protocol |egrep "USB|FireWire|Thunderbolt")" ] &&
    diskutil unmount $i
    SendToLog "$i is unmounted"
    echo "Result is: " $?
done
echo "---"

echo $List_of_Outer_Vol_WO_WLV

[ "$List_of_Outer_Vol_WO_WLV" ] &&
echo "Some disk is unmonted!"




