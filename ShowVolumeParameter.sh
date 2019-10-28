#!/bin/sh
# Get parameter value from disk name (for PreventMountVolume.sh)
#

# For the cases , volume-name contains $IFS..., Change $IFS to $'\001'
IFS_old=$IFS
IFS=$'\001'

printf "Please enter Volume-name: "
read ANS

myName=$(
    diskutil info $ANS  |
    grep "Volume Name:" |
    cut -b 31-
)

myData=$(
    diskutil info $ANS  |
    grep "File System Personality:\|Protocol:\|Volume UUID:\|Partition UUID:" |
    sed 's/^.*:[ ]*//g' |
    tr '\n' ','         |
    sed 's/,$//g'
)

# For the cases of no "Partition UUID" (may be MBR/FAT)..., add ",*" to the end
[ $(echo $myData |grep -o , |wc -l) -eq 2 ] &&
myData=$myData",*"

echo "The values are: (also copied to the clipboard..)"
echo "$myName"$'\n'"$myData" |tee /dev/stderr |pbcopy

IFS=$IFS_old

