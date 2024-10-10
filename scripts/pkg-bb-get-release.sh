#!/bin/bash

##########################################################################################################
# Script Name:pkg-bb-get.sh
# Description: This script will retrieve bb package and place in s3
# Author     : Larry Sprouse
# Version    : 1.0.0
#              .....
##########################################################################################################

##########################################################################################################
# Begin Get Variables
##########################################################################################################

today=$(date +"%m-%d-%Y-%H.%M.%S-%Z")
#Ansi colors
green="\e[0;92m"
red="\e[0;91m"
reset="\e[0m"
yellow="\e[0;93m"

##########################################################################################################
# Functions
##########################################################################################################

checkUser () {
  getUser=$(whoami)
  if [[ "${getUser}" != "maintuser"  ]]; then
    echo -e "${RED}This script needs to be executed as maintuser, exiting script!${NC}"
    exit 1
  fi
}

function yes_or_no () {
    echo
    while true; do
       read -p "$* [y/n]: " yn
       echo
       case $yn in
            [Yy]*) echo; return 0  ;;
            [Nn]*) echo -e "Aborted..."; exit ;;
        esac
    done
}

##########################################################################################################
# Main
##########################################################################################################
source /bootstrap/scripts/odin-logo.sh
checkUser

echo
read -p "Select BB package to create : " FOLDER
if [ ! -d "/bootstrap/bb-core/${FOLDER}" ] || [ -z  "$FOLDER" ]; then
   mkdir -p /bootstrap/bb-core/$FOLDER
   cd /bootstrap/bb-core/$FOLDER
else
   echo  "Folder exists already... Aborting"
   exit
fi

FILE=bigbang-$FOLDER.tar.gz
echo -e "${yellow}Getting $FILE...${reset}"
curl -o $FILE  https://repo1.dso.mil/big-bang/bigbang/-/archive/$FOLDER/bigbang-$FOLDER.tar.gz
aws s3 cp $FILE s3://konvoy-bootstrap/bb-core/$FOLDER/

FILE=repositories.tar.gz
echo -e "${yellow}Getting $FILE...${reset}"
curl -o $FILE https://umbrella-bigbang-releases.s3-us-gov-west-1.amazonaws.com/umbrella/$FOLDER/$FILE
aws s3 cp $FILE s3://konvoy-bootstrap/bb-core/$FOLDER/

FILE=package-images.yaml
echo -e "${yellow}Getting $FILE...${reset}"
curl -o $FILE https://umbrella-bigbang-releases.s3-us-gov-west-1.amazonaws.com/umbrella/$FOLDER/$FILE
aws s3 cp $FILE s3://konvoy-bootstrap/bb-core/$FOLDER/

FILE=images.txt
echo -e "${yellow}Getting $FILE...${reset}"
curl -o $FILE https://umbrella-bigbang-releases.s3-us-gov-west-1.amazonaws.com/umbrella/$FOLDER/$FILE
aws s3 cp $FILE s3://konvoy-bootstrap/bb-core/$FOLDER/

FILE=images.tar.gz
echo -e "${yellow}Getting $FILE...${reset}"
curl -o $FILE https://umbrella-bigbang-releases.s3-us-gov-west-1.amazonaws.com/umbrella/$FOLDER/$FILE
aws s3 cp $FILE s3://konvoy-bootstrap/bb-core/$FOLDER/

FILE=bigbang-${FOLDER}_checksums.txt
echo -e "${yellow}Getting $FILE...${reset}"
curl -o $FILE https://umbrella-bigbang-releases.s3-us-gov-west-1.amazonaws.com/umbrella/$FOLDER/$FILE
aws s3 cp $FILE s3://konvoy-bootstrap/bb-core/$FOLDER/

ls -al /bootstrap/bb-core/$FOLDER

echo
echo -e "${green}Script completed${reset}"
echo

