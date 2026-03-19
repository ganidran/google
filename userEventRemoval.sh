#!/bin/bash
#
# Removes a user as attendee from Google Calendar events after a given date,
# then optionally uploads the offboarded user folder to a Shared Drive via a Python script.

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

# Require GAM ADV (not legacy GAM); exit with instructions if missing or wrong version.
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

# Validate and collect user email (company.com domain).
emailPattern='^[a-zA-Z0-9._%+-]+@company\.com$'
while true; do
    read -r -p "Enter offboarding user email: " userEmail
    if [[ $userEmail =~ $emailPattern ]]; then
        break
    else
        printf "Error: Invalid email format or incorrect domain.\n\n"
    fi
done

# Validate and collect cutoff date (YYYY-MM-DD).
datePattern='^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
while true; do
    read -r -p "Delete all events after this date (YYYY-MM-DD format): " offDate
    if [[ $offDate =~ $datePattern ]]; then
        break
    else
        printf "Error: Invalid date format. Please enter a date in YYYY-MM-DD format.\n\n"
    fi
done

# Confirm before proceeding.
printf "\nEmail: %s is a valid format. Date: %s is the valid format.\n\n" "$userEmail" "$offDate"
read -r -p "Are you sure you want to proceed with removing user '$userEmail' as attendee from all events after $offDate? (y/n) " confirm
if [[ "$confirm" != "y" ]]; then
    printf "Operation cancelled.\n\n"
    exit 1
else
    printf "Removing  %s...\n\n" "$userEmail calendar items"
fi
sleep 1

###########################
#### SETTING VARIABLES ####
###########################

# Offboarded user folder path (defined before logFile).
userPath=$HOME/Offboarded/$userEmail
today=$(date +%Y-%m-%d)
gamPath="$HOME/bin/gamadv-xtd3/gam"
logFile="$userPath/logFile-calEvents-$today.txt"
calEventList="$userPath/calEvents-$today.csv"

###########################
###### DO THE THINGS ######
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

# Run calendar removal steps and append output to log file.
operation() {
printf "\n\n--START--\n\n"
echo "Unarchiving the user"
$gamPath update user "$userEmail" archive off
sleep 1
printf "\n\n--/--\n\n"

echo "Unsuspending the user"
$gamPath update user "$userEmail" suspended off
sleep 1
printf "\n\n--/--\n\n"

echo "Grabbing all Calendar events"
$gamPath calendar "$userEmail" print events after "$offDate" fields organizer.email,recurringEventId,summary,created,status > "$calEventList"
sleep 1
printf "\n\n--/--\n\n"

echo "Removing user from normal events."
$gamPath csv "$calEventList" gam calendar ~organizer.email update event id ~id removeattendee "$userEmail"
sleep 1
printf "\n\n--/--\n\n"

echo "Removing user from recurring events."
$gamPath csv "$calEventList" gam calendar ~organizer.email update event id ~recurringEventId removeattendee "$userEmail"
sleep 1
printf "\n\n--/--\n\n"

echo "Removing remaining events from primary calendar view"
$gamPath calendar "$userEmail" delete events after "$offDate" doit sendnotifications false
printf "\n\n--/--\n\n"
}

echo "Creating log file"
touch "$logFile"
echo "Event removal process starting. This will take some time so please keep the terminal window open until complete..."
operation "$@" >> "$logFile" 2>&1

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
