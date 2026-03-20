#!/bin/bash
#
# Checks the local GAM7 version against the latest GitHub release and
# runs the official install script to update if they differ.

echo "--Checking GAM version..."

###########################
###### SET VARIABLES ######
###########################

# Resolve the running user for path construction.
currentUser=$(id -un)

# Path to local GAM binary and its reported version.
gam="/home/$currentUser/bin/gam7/gam"
currentVersion=$("$gam" version | head -n 1 | cut -d " " -f 2)

# Fetch latest release tag from GitHub (strip leading "v").
latestVersion=$(curl -s https://api.github.com/repos/GAM-team/GAM/releases/latest | grep '"tag_name":' | cut -d '"' -f 4 | sed 's/^v//')

###########################
#### COMPARE VERSIONS #####
###########################

# If versions match, report and exit; otherwise run the official updater.
if [ "$currentVersion" = "$latestVersion" ]; then
    echo "--GAM is running the latest version - $currentVersion!"
else
    printf "\n--GAM is about to update from $currentVersion to $latestVersion! Please wait...\n\n"
    sleep 1
    # Update GAM using the latest installer from GitHub
    bash <(curl -s -S -L https://git.io/gam-install) -l

    # Re-check installed version after update
    newVersion=$("$gam" version | head -n 1 | cut -d " " -f 2)
    printf "\n--GAM updated from %s to %s\n" "$currentVersion" "$newVersion"
fi
