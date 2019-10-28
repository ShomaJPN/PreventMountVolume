#!/bin/bash
##
## ---This is test-drive version---
##
## Name:
##  PreventMountVolume.sh
##  Created by SHOMA on 9/13/2019. Last edited by SHOMA 10/29/2019
##
## Overview
##  Prevent (or control) mounting of external volumes, e.g. USB thumb drive.
##  White-volumes to mount are specified by Protocol(USB,Thunderbolt, PCI-Express,
##  SATA..),UUID, VolumeName, and conbination thereof.
##
## Description
##  Simple implementaion using launchd's StartOnMount trigger.(Not use fstab(5))
##  Do not specifying only the VolumeName ,because it is not perfect in this ver.
##
## Requirements:
##  -macOS
##  - Bash (for ShellScript)
##   - osascript (for FinderDialog)
##  -Test under macOS 10.14.6
##
## Install and Run:
##  - Prepare to use PreventMountVolume.sh
##   - Create WhiteVolumeList parameter and add it to this script (variable-area)
##   - Put this script to the appropriate directory (ex.~/Script) and set Excutable
##
##  - Use with launchd/lauchctl
##   - Make commnad-plist file and put it ~/Library/LaunchAgents/
##    - Start is ... following command (only the first time)
##       launchctl load ~/Library/LaunchAgents/some.plist
##  　- Stop is ...
##       launchctl unload ~/Library/LaunchAgents/some.plist
##    - Stop forever...
##       Remove plist (e.g. rm command)
##    - Check is ...
##       launchctl list
##
##  - A confirmation dialog (xxx would like to control "System Events"...)
##    appear at the first run, then allow it.  
##
## References:
##  If you did not confirm it by mistake, try "$ tccutil reset AppleEvents"
##  If you want to apply all users, please consider to put commnad-plist into
##  /Library/LaunchAgents/
##
##
## Should be implemented in the future:
##   -VolumeName Exact-match func. 
##
## Author: SHOMA Shimahara <shoma@yk.rim.or.jp>
##




######################## Set "Log" file and function ###########################

LogPath="$HOME/log"
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





############################### Set Variables ##################################
#
# Name:
#   1.WhiteListVolumes
#   2.Mes
#
#
# Details
#   1.WiteListVolumes
#   
#     Discription:
#       The list of Volumes's Parameters that are allowed to be mounted.
#
#     Usage:
#       - Format -
#
#         VolName1
#         FileSystem,Protcol,UUID(Volume),UUID(Partition)
#
#         VolName2
#         FileSystem,Protcol,UUID(Volume),UUID(Partition)
#         ...
#         ...
#
#       These are given by "$diskutil info diskXsX" ,and "ShowVolumeParameter.sh" could
#       help it
#       Also you can use wildcards(*).
#
#     Reference:
#
#       -FileSystem ($ diskutil listFilesystems)
#        APFS,Journaled HFS+,MS-DOS FAT16,MS-DOS FAT32 ...
#
#       -Protcol
#        PCI-Express,USB,ATA,FireWire,Thunderbolt ...
#
#       -UUID(Volume)
#        $ diskutil info diskXsX |sed -n '/Volume UUID/{;s/^.*Volume UUID:[ ]*//p;}'
#
#       -UUID(Partition)
#        $ diskutil info diskXsX |sed -n '/Partition UUID/{;s/^.*Partition UUID:[ ]*//p;}'
#
#     Remark:
#       In the case of no "Partition UUID" (..possibly MS-Windows disk), write "*" 
#       in that section 
#
#
#   2.Mes
#
#     Discription:
#       Messages notifying user to the volume-name of ejected
#
#     Usage:
#       %EjectVolumes is replaced by the volume-name of ejected
#
#

WhiteListVolumes="
UNTITLED
MS-DOS FAT32,USB,3EA622AA-C788-3C5E-9EBB-A9A1AF2A4B28,*

LGT_USB_16G2_APFS
APFS,USB,47F2EB48-8878-4B6B-BEC4-7436610B5A30,47F2EB48-8878-4B6B-BEC4-7436610B5A30

LGT_USB_8GB_HFS
Journaled HFS+,USB,CDDD66E9-36F5-309F-AAF0-9FACBD1A01B0,2EE2E792-8F14-48F4-B307-8C284415B8F5
"

Mes="
IT support team

%EjectVolumes

was/were ejected, due to the organizational policy.

If you are unsure, contact the IT support team (tel.xxx-xxxx-xxxx)

"


############################# End of Variables #################################





############################## Set Functions ###################################
#
# Name:
#  1.function MakeWhiteListVolumeParameter()
#  2.function GetOuterVolumeList()
#  3.function GetMyVolumeNameAndData()
#  4.function MakeWhiteListNameAndData()
#
# Details:
#  1.function MakeWhiteListVolumeParameter()
#
#    Discription:
#      Simple Check $WhiteListVolumes and Create $WhiteListVolumeParameter
#        -Simple Check
#           -Delete blank-lines
#           -Check Parity of Number of lines (Even:OK/Odd:exit) 
#           -Check Number of parameters in data-part (4:OK/others:exit))
#
#        -Create $WhiteListVolumeParameter
#         Join Name<>Data-part in $WhiteListVolumes and change word-separator
#         "," to "\001"
#         This is for the case that Volume-name contains "space","comma" etc..
#
#    Requirements:
#      $WhiteListVolumes (is given in correct format)
#
#    Output:
#      $WhiteListVolumeParameter
#      
#
#
#  2.function GetOuterVolumeList()
#
#    Discription:
#      Get StartUpVolume,Disk and OuterVolumesList
#
#    Requirements:
#      NA
#
#    Output:
#      $StartupVolume, $StartupDisk, $ListOfOuterVolumes
#
#
#
#  3.function GetMyVolumeNameAndData()
#
#    Discription:
#      Get Volume-name and Volume-data from $myVolume
#
#    Requirements:
#      $myVolume (ex. /dev/diskXsX)
#
#    Output:
#      $myVolumeName,$myVolumeData
#
#      example: $myVolumeData -> APFS,USB,UUID(Volume),UUID(Partition)
#      
#
#
#  4.function MakeMyWhiteVolumeNameAndData()
#
#    Discription:
#      -Get $myWhiteVolumeName,$myWhiteVolumeData from $myWhiteListVolumeParameter
#      -Create $GrepWhiteVolumeData (for grep-match)
#
#    Requirements:
#      $myWhiteListVolumeParameter (is given in correct format)
#
#    Output:
#      $myWhiteVolumeName,$myWhiteVolumeData,$myGrepWhiteVolumeData
#
#


# ------------------------------------------------------------------------------
#  1.function MakeWhiteListVolumeParameter()
#
#

function MakeWhiteListVolumeParameter ()
{
WhiteListVolumes="$( echo "$WhiteListVolumes" |grep -v ^$ )"

# Simple Check -> $WhiteListVolumes
# 1/2.Check the parity of the number of lines
[ $(( $(echo "$WhiteListVolumes" |wc -l) % 2 )) -eq "1" ] && 
echo "Number of WhiteListVolumes's Line is Odd" &&
exit 0

# 2/2.Check the number of parameters (in data-part)
j="1"
while read i ;do
  if [ $(( j % 2)) -eq 0 ] ; then          # choose data-part
    [ $(echo "$i" | grep -o ',' |wc -l) -ne "3" ] &&
    echo "Number of WhiteListVolume's parameter is wrong" &&
    exit 0
  fi
  j=$(( j + 1 ))
done <<EOD
$WhiteListVolumes
EOD

# Create $WhiteListVolumeParameter from $WhiteListVolumes
# For the cases that special-characters (such as $IFS) are present in volume-name,
# make $IFS ="" then Join Strings with $'\001' .

IFS_old=$IFS
IFS=""

j="1"   # Odd/Even line determinant

# Read every records from $WhiteListVolumes, and Add New Recode or Join Data.
while read i ;do

    if [ "$j" -eq "1" ] ;then             #$j=1/ FirstRecord..VolumeName -> Add New Record
        WhiteListVolumeParameter="$i"

    elif [ "$(( j % 2 ))" -eq "0" ] ;then #Even/ NextField..Protcol,UUID,etc  -> Join Data
        WhiteListVolumeParameter="$WhiteListVolumeParameter"$'\001'"$i"$'\n'

    elif [ "$(( j % 2 ))" -eq "1" ] ;then #Odd/ NextRecord..VolumeName   -> Add New Record
        WhiteListVolumeParameter="$WhiteListVolumeParameter""$i"
    fi

    j=$(( j + 1 ))

done <<EOD
$WhiteListVolumes
EOD

IFS="$IFS_old"

# Delete last blank-line
WhiteListVolumeParameter="$( echo "$WhiteListVolumeParameter" |grep -v ^$ )"


# for debug
echo '$WhiteListVolumeParameter:'
echo "$WhiteListVolumeParameter"

}



# ------------------------------------------------------------------------------
# 2.function GetOuterVolumeList()
#
#

function GetOuterVolumeList()
{
StartupVolume=$(df / |grep ^/dev |cut -d' ' -f1)
StartupDisk=$(echo $StartupVolume |sed 's/s[0-9]*$//')
ListOfOuterVolumes=$(df |grep ^/dev |cut -d' ' -f1 |grep -v "$StartupDisk"s)

# for debug
echo '$ListOfOuterVolumes:'
echo "$ListOfOuterVolumes"
}


# ------------------------------------------------------------------------------
# 3.function GetMyVolumeNameAndData()
#
#

function GetMyVolumeNameAndData()
{
myVolumeName=$( diskutil info $myVolume |grep "Volume Name:" |cut -b 31- )
myVolumeData=$(
  diskutil info $myVolume |
  grep "File System Personality:\|Protocol:\|Volume UUID:\|Partition UUID:" |
  sed 's/^.*:[ ]*//g' |
  tr '\n' ',' |
  sed 's/,$//'
)

# For the cases of no "Partition UUID" (e.g. MBR/FAT) , add data
[ "$( echo $myVolumeData |grep -o ',' |wc -l )" -eq "3" ] ||
myVolumeData=$myVolumeData",*"
}


# ------------------------------------------------------------------------------
# 4.function MakeMyWhiteVolumeNameAndData()
#
#

function MakeMyWhiteVolumeNameAndData()
{
    myWhiteVolumeName=$( echo $myWhiteListVolumeParameter | cut -d$'\001' -f1 )
    myWhiteVolumeData=$( echo $myWhiteListVolumeParameter | cut -d$'\001' -f2 )
    myGrepWhiteVolumeData=$( echo "$myWhiteVolumeData" | sed 's/*/.*/g' )
}


############################ End of Functions ###################################





################################# Processing ###################################
#
# Compare every OuterVolumes's Volume-name/data with WhiteListVolumeParameter
# Repeated multiple times to accommodate slow-mounting-volumes.
#


# file that write ejected-volume-name (temp file)
EjectLogPath=$HOME/log
EjectLogFile=$LogPath/Eject$$.log

SendToLog "Volume Check is started!"

# Repeated multiple times to accommodate slow-mounting-volumes.
myCount=1

for myCount in {1..10};do

  SendToLog $( echo $myCount ) "/10"

  # Check and make White-list Volume Parameter
  MakeWhiteListVolumeParameter    # $WhiteListVolumes -> $WhiteListVolumeParameter

  # Get Outer Volume list
  GetOuterVolumeList              #                   -> $ListOfOuterVolumes

  # Use only LF(\n) as character-delimiters in "for" control statements
  IFS_bak=$IFS
  IFS=$'\n'

  # Check every OuterVolume to "Eject" or "Still Mount"
  # Select one myVolume (from $ListOfOuterVolumes)
  for myVolume in $ListOfOuterVolumes ;do

    # Define eject-determinant
    myDeterminant="0"              # 0 -> Eject Volume, 1 -> Still Mount

    # Get myVolume-name/data
    GetMyVolumeNameAndData         # $myVolume -> $myVolumeName , $myVolumeData

    # Compare "myVolume-name/data" with "all WhiteVolume-name/data" in $WhiteListVolumeParameter
    # And if there ,change $myDeterminant to "1" (Still Mount)
    while read myWhiteListVolumeParameter ;do

      # Make myWhiteVolume-name/data
      MakeMyWhiteVolumeNameAndData # $myWhiteListVolumeParameter -> $myWhiteVolumeName ,$myGrepWhiteVolumeData

      # Compare
      [ "$myVolumeName" = "$myWhiteVolumeName" -o "$myWhiteVolumeName" = "*" ] && # Compare Name (Exact-match)
      [ $( echo "$myVolumeData" |grep "$myGrepWhiteVolumeData" ) ]             && # Compare Data (grep-match)
      myDeterminant="1" && break                                                  # Change Determinant
    
    done <<-EOD
$WhiteListVolumeParameter
EOD

    # if this volume's eject-determinat is "0", Eject volume
      [ "$myDeterminant" = "0" ]                             &&
      diskutil unmount force $myVolume                       &&
      SendToLog "$myVolumeName($myVolumeData) is Unmounted!" &&
      echo " - $myVolumeName -" | tee -a "$EjectLogFile"

  done

  IFS=$IFS_bak

done


# Display Dialog & Logging..
[ -f $EjectLogFile ]                                            &&
 EjectVolumes=$(cat $EjectLogFile)                              &&
 echo "EjectVolumes: $EjectVolumes"             　              &&
 Mes=$(echo "$Mes" |perl -pe "s/%EjectVolumes/$EjectVolumes/g") &&
 osascript <<-EOD &>/dev/null                                   &&
  tell application "System Events" to display dialog "$Mes" buttons {"OK"} with title "Caution" with icon 2 giving up after 10
EOD
 rm $EjectLogFile                                               &&
 SendToLog "EjectVolumes: ""$EjectVolumes"
