# Google Collection

## Overview

This repository contains a collection of scripts designed to automate administrative tasks for Google Workspace using Google Apps Manager (GAM). These scripts are tailored to manage users, groups, settings, and other aspects of your Google Workspace environment efficiently.

## Details
*These scripts assume you have GAM installed. Scripts below that utilize GAM do check if it's installed. Feel free to edit the check with documentation online, your own or remove entirely* 
<details>
<summary markdown="span"><strong>Check GAM Version</strong></summary>
<br>
  
[gamCheck](https://github.com/ganidran/google/blob/main/gamCheck.sh) | 
Checks the version of GAM everytime a shell is launched to make sure it's running the latest version.
<br><br>

</details>

<details>
<summary markdown="span"><strong>Google User Offboard</strong></summary>
<br>
  
[googleOffboard](https://github.com/ganidran/google/blob/main/googleOffboard.sh) | 
A robust offboarding script to use in GAM for Google users. This script features a check when the script is run if the user is an employee or contractor and files them away in their respective OUs at the end, it also creates a folder specific to the user and adds all files and logs to that folder for easy and organized access. Make sure to go over every command to see how it can best be used. At the near end, there is a portion to move the folder and its contents to a Google Shared Drive. Presumably and IT shared drive of sorts. It utilizes the script below in tandem to accomplish this. Be sure to modify the "Python script variables" in this script. 
<br><br>

</details>

<details>
<summary markdown="span"><strong>Data Importer (to Google Drive)</strong></summary>
<br>
  
[importDataToDrive](https://github.com/ganidran/google/blob/main/importDataToDrive.py) | 
Python script that works with the 'googleOffboard' script above using the variables specified there. 
<br><br>

</details>

<details>
<summary markdown="span"><strong>Google User Event Removal</strong></summary>
<br>
  
[userEventRemoval](https://github.com/ganidran/google/blob/main/userEventRemoval.sh) | 
This is used when a user is no longer at a company, their profile is archived rather than deleted and when we need to remove them from any Google Cal invite so as to not see their email pop up within invites. This is done **after** their calendar has been transferred via Google Admin GUI and still some rogue events exist with them. Utilizes the same python script above to export data to a Shared Drive if needed after placing all outputs in the user's folder. 
<br><br>

</details>

## License

This project is licensed under the [MIT License](https://www.mit.edu/~amini/LICENSE.md).
