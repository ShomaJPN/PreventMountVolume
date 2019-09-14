# PreventMountVolume (macOS)

## Overview
This Bash ShellScripts help to prevent (or control) mounting of external volumes.  
According to the organization's policy, this script could be designed to prevent certain external disk connections, e.g. USB thumb drive.

## Description
Simple implementaion because it uses launchd's StartOnMount trigger.

## Requirements
- Bash (for ShellScript)
  - osascript (for FinderDialog)

- Tested under Mojave 10.14.6 (Confrim Dialog/TCC appear at the first run)

## Usage
Excute ShellScripts with launchctl / launchd.
- PreventMountVolume.sh
- com.myOrganization.PreventMountVolume.plist    <-- Sample /launchd's command plist file


## Install and Run
Put ShellScripts to the appropriate directory  `(ex.~/Script)`  , and set execute permissions.  
Make or change launchd's command plist file, then put it to the appropriate directory. `(ex.~/Library/LaunchAgents)`  

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
