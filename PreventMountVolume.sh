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
##  Do not specifying White-volumes only by the VolumeName ,because it is not
##  perfect in this ver.
##
## Requirements:
##  -macOS
##  - Bash (for ShellScript)
##   - osascript (for FinderDialog)
##   - perl (for variable-replacement )
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
##    - Stop is ...
##       launchctl unload ~/Library/LaunchAgents/some.plist
##    - Stop forever...
##       Remove plist (e.g. rm command)
##    - Check is ...
##       launchctl list
##
##  - A confirmation dialog (xxx would like to control "System Events"...)
##    appear at the first run, then allow it.
##    If you do not allow by mistake, try "$ tccutil reset AppleEvents"
##
## References:
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
#   1.WhiteListVolumes : Volumes's Parameters allowed to be mounted.
#   2.Mes              : User notify messages
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
#       These are given by "$diskutil info diskXsX" ,and "ShowVolumeParameter.sh"
#       could help it
#       Also you can use wildcards(*).
#
#     References:
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
#       If there is no "Partition UUID" (..possibly MS-Windows disk), write "*" 
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

3TB
Journaled HFS+,USB,6A372893-B7A6-38CE-8C8A-C05A72ED1AC9,90039037-75FE-4A1B-B165-3A048C2DCA6F
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
#  2.function GetOuterVolumeList()
#
#    Discription:
#      Get StartUpVolume,Disk and OuterVolumesList
#
#    Requirements:
#      NA
#
#    Output:
#      $StartupDisk, $StartupVolume, $ListOfOuterVolumes
#
#
#  3.function GetMyVolumeNameAndData()
#
#    Discription:
#      Get Volume name,data from Volume Identifer(ex. /dev/diskXsX)
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
#  4.function MakeMyWhiteVolumeNameAndData()
#
#    Discription:
#      Decompress WhiteVolumeName,Data from WhiteListVolumeParameter
#      Make grep-comparison data
#
#    Requirements:
#      $myWhiteListVolumeParameter (is given in correct format)
#
#    Output:
#      $myWhiteVolumeName,$myWhiteVolumeData,$myGrepWhiteVolumeData
#
#


# ------------------------------------------------------------------------------

function MakeWhiteListVolumeParameter ()
{

WhiteListVolumes="$( echo "$WhiteListVolumes" |grep -v ^$ )"       # ReFormat. Delete blank-line

[ $(( $(echo "$WhiteListVolumes" |wc -l) % 2 )) -eq "1" ]    &&    # Check1. Parity of the number of lines
    echo "Number of WhiteListVolumes's Line is Odd"          &&
    exit 1
                                                                   # Check2. Number of parameters (in data-part)
j="1"                                                                # Name/Data-line determinant
echo "$WhiteListVolumes"                                     |
while read i ;do
    [ $(( j % 2 )) -eq 0 ]                                   &&      # choose Data-line
    [ $(echo "$i" | grep -o ',' | wc -l) -ne "3" ]           &&      # count parameters
    echo "Number of WhiteListVolume's parameter is wrong"    &&
    exit 1
    j=$(( j + 1 ))
done                                                         ||
exit 1

# For the cases of special-characters (such as $IFS) in volume-name,
# make $IFS ="" then join data with $'\001' .

IFS_old=$IFS
IFS=$'\n'

# Make $WhiteListVolumeParameter from $WhiteListVolumes
#
# Read $WhiteListVolumes..then..
#
#   1st line ($j=1) and Odd line -> Make new record
#   Even line                    -> Add data to current record with $'\001'
#
#  ex.
#     $WhiteListVolumes -> $WhiteListVolumeParameter
#       VolName1
#       VolData1        ->   VolName1 $'\001' VolData1
#       VolName2
#       VolData2        ->   VolName2 $'\001' VolData2
#       ..                   ..
#

j="1"                                            # Odd/Even line determinant
for i in $WhiteListVolumes ;do

    if [ "$j" -eq "1" ] ;then
        WhiteListVolumeParameter="$i"

    elif [ "$(( j % 2 ))" -eq "1" ] ;then
        WhiteListVolumeParameter="$WhiteListVolumeParameter"$'\n'"$i"

    elif [ "$(( j % 2 ))" -eq "0" ] ;then
        WhiteListVolumeParameter="$WhiteListVolumeParameter"$'\001'"$i"
    fi

    j=$(( j + 1 ))

done

IFS="$IFS_old"


# for debug
echo '$WhiteListVolumeParameter:'
echo "$WhiteListVolumeParameter"

}


# ------------------------------------------------------------------------------

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

function MakeMyWhiteVolumeNameAndData()
{
    myWhiteVolumeName=$( echo $myWhiteListVolumeParameter | cut -d$'\001' -f1 )
    myWhiteVolumeData=$( echo $myWhiteListVolumeParameter | cut -d$'\001' -f2 )
    myGrepWhiteVolumeData=$( echo "$myWhiteVolumeData" | sed 's/*/.*/g' )
}


############################ End of Functions ###################################





################################# Processing ###################################
#
# Compare Volume-name/data of OuterVolumes with WhiteListVolumeParameter
#
# -flow---
# 0.Read WhiteListVolumes and make WhiteListVolumeParameter
# 1.Choose one OuterVolume
#  2.-> Get VolumeName and VolumeData
#   3.-> Choose one WhiteVolumeParameter
#    4.-> Make WhiteVolumeName and WhiteVolumeData
#     5.-> Compare VolumeName <> WhiteVolumeName ,VolumeData <> WhiteVolumeData
#      6.-> Eject Volume or not
#   7.-> Loop(to 3.)
# 8.-> Loop(to 1.)
# 9.Display Dialog & Logging ...
#
# Remark:
#   Repeated multiple times to accommodate slow-mounting-volumes.
#
#


SendToLog "Volume Check is started!"
MakeWhiteListVolumeParameter                                                                # -> $WhiteListVolumeParameter

myCount="1"
for myCount in {1..10};do                                                                   # Repeated for slow-mounting-volumes loop \\\\
    SendToLog $( echo $myCount ) "/10"
    GetOuterVolumeList
                                                                                               # Set $IFS to "\n" in "for" control statements
    IFS_bak=$IFS
    IFS=$'\n'
                                                                                            ## Choose one OuterVolume loop start================
    for myVolume in $ListOfOuterVolumes ;do
      EjectDeterminant="0"                                                                     # Init Determinant : 0 -> Eject/ 1 -> Mount
      GetMyVolumeNameAndData
                                                                                            ## Choose one WhiteVolumeParameter loop start-------
      for myWhiteListVolumeParameter in $WhiteListVolumeParameter ;do
          MakeMyWhiteVolumeNameAndData

          [ "$myVolumeName" = "$myWhiteVolumeName" -o "$myWhiteVolumeName" = "*" ] &&          # Compare Name (Exact-match)
          [ $( echo "$myVolumeData" |grep "$myGrepWhiteVolumeData" ) ]             &&          # Compare Data (grep-match)
            EjectDeterminant="1" && break                                                      # Change Determinant
      done
                                                                                            ## Choose one WhiteVolumeParameter loop end---------
                                                                                               # Eject volume 
      [ "$EjectDeterminant" = "0" ]                              &&
        diskutil unmount force $myVolume                         &&
        SendToLog "$myVolumeName($myVolumeData) is Unmounted!"   &&
        EjectVolumes="$EjectVolumes"$'\n'" - $myVolumeName -"
    done
                                                                                            ## Choose one OuterVolume loop end=================
    IFS=$IFS_bak
done
                                                                                            # Repeated for slow-mounting-volumes loop end \\\\


# Display Dialog & Logging..
[ -n "$EjectVolumes" ]                                             &&
    Mes=$(echo "$Mes" |perl -pe "s/%EjectVolumes/$EjectVolumes/g") &&
    osascript <<-EOD &>/dev/null                                   &&
      tell application "System Events" to display dialog "$Mes" buttons {"OK"} with title "Caution" with icon 2 giving up after 10
EOD
    SendToLog "EjectVolumes: ""$EjectVolumes"


