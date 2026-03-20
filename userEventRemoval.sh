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

# Require GAM7; exit with instructions if missing or if only legacy GAM is installed.
if [ -d "$HOME/bin/gam7" ]
then
    printf "GAM7 exists. Proceeding...\n\n"
elif [ -d "$HOME/bin/gam" ]
then
    printf "Only GAM is installed. Please install 'GAM7' via: https://github.com/GAM-team/GAM/wiki/How-to-Upgrade-GAMADV-XTD3-to-GAM7 or reset your Cloud Shell then follow our Wiki: <Insert Internal Documentation Link Here>\n\n"
    exit 1
elif [ -d "$HOME/bin/gamadv-xtd3" ]
then
    printf "GAMADV-XTD3 is installed. Please install 'GAM7' via: https://github.com/GAM-team/GAM/wiki/How-to-Upgrade-GAMADV-XTD3-to-GAM7 or reset your Cloud Shell then follow our Wiki: <Insert Internal Documentation Link Here>\n\n"
    exit 1
else
    printf "GAM is not installed. Please install it by following our Wiki: <Insert Internal Documentation Link Here>\n\n"
    exit 1
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
gam="$HOME/bin/gam7/gam"
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
$gam update user "$userEmail" archive off
sleep 1
printf "\n\n--/--\n\n"

echo "Unsuspending the user"
$gam update user "$userEmail" suspended off
sleep 1
printf "\n\n--/--\n\n"

echo "Grabbing all Calendar events"
$gam calendar "$userEmail" print events after "$offDate" fields organizer.email,recurringEventId,summary,created,status > "$calEventList"
sleep 1
printf "\n\n--/--\n\n"

echo "Removing user from normal events."
$gam csv "$calEventList" gam calendar ~organizer.email update event id ~id removeattendee "$userEmail"
sleep 1
printf "\n\n--/--\n\n"

echo "Removing user from recurring events."
$gam csv "$calEventList" gam calendar ~organizer.email update event id ~recurringEventId removeattendee "$userEmail"
sleep 1
printf "\n\n--/--\n\n"

echo "Removing remaining events from primary calendar view"
$gam calendar "$userEmail" delete events after "$offDate" doit sendnotifications false
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
