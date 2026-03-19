#!/bin/bash
#
# Checks the local GAMADV-XTD3 version against the latest GitHub release and
# runs the official install script to update if they differ.

echo "--Checking GAM version..."

###########################
###### SET VARIABLES ######
###########################

# Resolve the running user for path construction.
currentUser=$(id -un)

# Path to local GAM binary and its reported version.
gamPath="/home/$currentUser/bin/gamadv-xtd3/gam"
currentVersion=$("$gamPath" version | head -n 1 | cut -d " " -f 2)

# Fetch latest release tag from GitHub (strip leading "v").
latestVersion=$(curl -s https://api.github.com/repos/taers232c/GAMADV-XTD3/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/^v//')

###########################
#### COMPARE VERSIONS #####
###########################

# If versions match, report and exit; otherwise run the official updater.
if [ "$currentVersion" = "$latestVersion" ]; then
  echo "--GAM is running the latest version: $currentVersion"
else
  echo "Current GAM: $currentVersion. Latest version: $latestVersion"
  printf "\n--GAM is about to update! Please wait...\n\n"
  sleep 1
  bash <(curl -s -S -L https://raw.githubusercontent.com/taers232c/GAMADV-XTD3/master/src/gam-install.sh) -l
fi
