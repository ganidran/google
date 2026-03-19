#!/bin/bash
#
# Offboards a Google Workspace user: resets password, revokes shared drives and
# groups, deprovisions apps, wipes MDM devices, delegates inbox, moves user to
# Archived OU, and optionally uploads the log folder to a Shared Drive.

###########################
###### CHECK FOR DIRS #####
###########################

# Ensure Offboarded folder exists in home directory.
if [ -d "$HOME/Offboarded" ]
then
    printf "Offboarded folder exists. Proceeding...\n\n"
else
    printf "Offboarded folder doesn't exist. Creating...\n\n"
    mkdir "$HOME"/Offboarded
fi

# Require GAM ADV; exit with instructions if missing or legacy GAM only.
if [ ! -d "$HOME/bin/gam" ] && [ ! -d "$HOME/bin/gamadv-xtd3" ]
then
    printf "GAM is not installed. Please install it by following our Wiki: <Insert Internal Documentation Link Here> \n\n"
    exit 0
elif [ -d "$HOME/bin/gam" ]
then
    printf "Only GAM is installed. Please install 'GAM ADV' via: https://github.com/taers232c/GAMADV-XTD3/wiki/How-to-Upgrade-from-Standard-GAM or reset your Cloud Shell then follow our Wiki: <Insert Internal Documentation Link Here> \n\n"
    exit 0
elif [ -d "$HOME/bin/gamadv-xtd3" ]
then
    printf "GAM ADV exists. Proceeding...\n\n"
fi

###########################
##### CHECK THE USER ######
###########################

# Validate and collect user email (company.com).
emailPattern='^[a-zA-Z0-9._%+-]+@company\.com$'
while true; do
    read -r -p "Enter offboarding user email: " userEmail
    if [[ $userEmail =~ $emailPattern ]]; then
        break
    else
        printf "Error: Invalid email format or incorrect domain.\n\n"
    fi
done

# Collect user type (employee or contractor).
userType=""
while [[ "$userType" != "employee" && "$userType" != "Employee" && "$userType" != "contractor" && "$userType" != "Contractor" ]]; do
    read -r -p "Enter user-type (contractor or employee): " userType
    if [[ "$userType" != "employee" && "$userType" != "Employee" && "$userType" != "contractor" && "$userType" != "Contractor" ]]; then
        printf "Error: Invalid user-type. Type 'Employee' or 'Contractor'.\n\n"
    fi
done

# Confirm before proceeding.
printf "\nEmail: %s is a valid format. Type: %s is a valid type.\n\n" "$userEmail" "$userType"
read -r -p "Are you sure you want to proceed with offboarding user '$userEmail'? (y/n) " confirm
if [[ "$confirm" != "y" ]]; then
    printf "Offboarding cancelled.\n\n"
    exit 1
else
    printf "Offboarding %s...\n\n" "$userEmail"
fi
sleep 1

###########################
#### SETTING VARIABLES ####
###########################

today=$(date +%Y-%m-%d)
gamPath="$HOME/bin/gamadv-xtd3/gam"
userPath=$HOME/Offboarded/$userEmail
logFile="$userPath/logFile-$today.txt"
mdmList="$userPath/mdmList-$today.csv"
shrdDrvList="$userPath/$userEmail-shrdDrv.csv"
managerEmail=$($gamPath info user $userEmail | awk '/type: manager/ {getline; print $2}')
itCal="<sharedGoogleCalendarId>"
ninetyDays=$(date -d "+90 days" +%Y-%m-%d)

###########################
##### SET UP FUNCTION #####
###########################

# Create user offboarding folder if it doesn't exist.
if [ -d "$userPath" ]
then
    printf "User offboarding folder exists. Proceeding...\n\n"
else
    printf "User offboarding folder doesn't exist. Creating...\n\n"
    mkdir "$userPath"
fi
printf "\n\n--/--\n\n"

# Perform full offboard: signout, shared drives, groups, deprovision, MDM wipe, delegate, calendar reminder, move OU.
offboard() {
printf "\n\n--START--\n\n"
echo "Resetting sign-in cookies and setting a random password"
$gamPath user "$userEmail" signout
$gamPath update user "$userEmail" password random
sleep 0.5
printf "\n\n--/--\n\n"

echo "Turning 'Directory Sharing' off"
$gamPath update user "$userEmail" gal off
sleep 0.5
printf "\n\n--/--\n\n"

echo "Creating list of all shared drives"
$gamPath user "$userEmail" print shareddrives fields id,name > "$shrdDrvList"
echo "Removing shared drive access"
$gamPath csv "$shrdDrvList" gam delete drivefileacl ~id ~User

echo "Removing user from Google Groups"
$gamPath user "$userEmail" delete groups
sleep 0.5
printf "\n\n--/--\n\n"

echo "Removing connected apps, backup codes and/or tokens"
$gamPath user "$userEmail" deprovision
sleep 0.5
printf "\n\n--/--\n\n"

echo "Creating list of managed mobile device resourceIds"
$gamPath config csv_output_header_filter "resourceId" redirect csv - > "$mdmList" print mobile query "email:$userEmail"
sleep 1
printf "\n\n--/--\n\n"

echo "Removing Google account from managed mobile device(s)"
$gamPath csv "$mdmList" gam update mobile ~resourceId action account_wipe
sleep 1
printf "\n\n--/--\n\n"

echo "Removing managed mobile device(s) from Google MDM"
$gamPath csv "$mdmList" gam delete mobile ~resourceId
sleep 0.5
printf "\n\n--/--\n\n"

echo "Delegating inbox to manager"
$gamPath user "$userEmail" delegate to "$managerEmail"
sleep 0.5
printf "\n\n--/--\n\n"

echo "Setting calendar reminder for admin"
$gamPath user "$itCal" create event summary "Suspend & Archive $userEmail" start allday "$ninetyDays" end allday "$ninetyDays" reminder 1 email
sleep 0.5
printf "\n\n--/--\n\n"

# Move user to Archived OU by type.
if [[ "$userType" == "Contractor" || "$userType" == "contractor" ]]; then
  echo "Moving user to Archived Contractors OU"
  $gamPath update user "$userEmail" ou "/Contractors/Archived Contractors"
else
  echo "Moving user to Archived Employees OU"
  $gamPath update user "$userEmail" ou "/Employees/Archived Employees"
fi
printf "\n\n--FIN--\n\n"
}

###########################
###### DO THE THINGS ######
###########################

echo "Creating log file"
touch "$logFile"
printf "Offboard process starting... \n\nThis may take longer than expected so please keep the terminal window open. \nA message will confirm once complete."
offboard "$@" >> "$logFile" 2>&1
echo "Almost there..."

###########################
## MV FOLDER TO IT DRIVE ##
###########################

# If Python upload script exists, run it; otherwise report local folder only.
sharedDriveId="<sharedDriveId>"
destinationFolderId="<sharedDriveFolderId>"
credentialsFile="$HOME/.gam/<credentialsFile.json>"
pyScript="$HOME/.gam/<pythonFile.py>"
if [[ -f "$pyScript" ]]; then
    python "$pyScript" "$userPath" "$sharedDriveId" "$destinationFolderId" "$credentialsFile"
    printf "\n\n--/--\n\n"
else
    printf "Process complete! Please check user offboarding folder in your local home directory.\n\n"
    printf "\n\n--/--\n\n"
fi

exit 0
