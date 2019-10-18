# PreventMountVolume (macOS)

## Overview
This Bash ShellScripts prevent (or control) mounting of external volumes.  
According to the organization's policy, this script prevent (or control) certain external disk connections, e.g. USB thumb drive.

## Description
Simple implementaion using launchd's StartOnMount trigger.(Not use fstab(5))  
The volume can be specified by Protocol(USB, Thunderbolt, PCI-Express, SATA..), UUID(Volume, Partition), VolumeName, and conbination thereof.

## Requirements
- Bash (for ShellScript)
  - osascript (for FinderDialog)

- Tested under Mojave 10.14.6 (Confrim Dialog/TCC appear at the first run)

## Usage
Excute ShellScripts with launchctl / launchd.
- PreventMountVolume.sh
- com.myOrganization.PreventMountVolume.plist    <-- Sample /launchd's command-plist file
- ShowVolumeParameter.sh   <-- Show specific volume parameters in variable-entry form (auxiliary)

## Install and Run
Write the White-list volume parameter in the PreventMountVolume.sh (WhiteListVolumes area)  
These parameters could be found with diskutil (8), and also ShowVolumeParameter.sh can help it.  
Put ShellScripts to the appropriate directory  `(ex.~/Script)`  , and set executable permissions.  

Make launchd's command-plist file to suit for your enviroment, then put it to the appropriate directory. `(ex.~/Library/LaunchAgents)`  

At the first run, confirmation dialog (xxx would like to control "System Events"...) is appeared.  
Please allow it (in the case of Mojave )  
If you did not allow it by mistake, try `$ tccutil reset AppleEvents`  

Start with the following command (only the first time)  
　```launchctl load /Path/to/plist```  
Stop is ...  
　```launchctl unload /Path/to/plist```  
Stop forever...  
　```Remove plist from the appropriate directory  (ex. rm command)```  
Check is ...  
　```launchctl list```  

## Author
SHOMA Shimahara : <shoma@yk.rim.or.jp>
