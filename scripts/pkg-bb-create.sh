#!/bin/bash

##########################################################################################################
# Script Name: pkg--bb-create.sh
# Description: This script will create bb package and send to high sides
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

function yes_or_no_flux () {
    echo
    while true; do
       read -p "$* [y/n]: " yn
       echo
       case $yn in
            [Yy]*) echo;
               echo
               aws s3 ls s3://konvoy-bootstrap/cli_tools/ | grep flux
               echo
               read -e -p "Enter  Flux Binary to add to package ? " BINARY_FILE
               cd ~
               cd ~/tmp/$FOLDER
               aws s3 cp s3://konvoy-bootstrap/cli_tools/$BINARY_FILE .
               return 0 ;;
            [Nn]*) echo -e "No Flux update..."; break ;;
        esac
    done
}

##########################################################################################################
# Main
##########################################################################################################

echo
#ls -lrth /bootstrap/bb-core/ | grep "^d" | awk '{ print $9}'
aws s3 sync s3://konvoy-bootstrap/bb-core/$FOLDER/ /bootstrap/bb-core/$FOLDER/
ls -lrth /bootstrap/bb-core/ | grep "^d" | awk '{ print $9}'
echo
read -p "Select BB package to create : " FOLDER
if [ ! -d "/bootstrap/bb-core/${FOLDER}" ] || [ -z  "$FOLDER" ]; then
   echo  "Incorrect folder choice... Aborting"
   mkdir -p /bootstrap/bb-core/$FOLDER
   aws s3 sync s3://konvoy-bootstrap/bb-core/$FOLDER/ /bootstrap/bb-core/$FOLDER/
   exit
fi

cd ~
mkdir -p ~/tmp/$FOLDER
cd ~/tmp/$FOLDER

echo
yes_or_no  "Did you export a pdf of the upgrade confluence document and upload to s3://konvoy-bootstrap/bb-core/$FOLDER ? "
yes_or_no_flux  "Was there a flux binary update in the BB upgrade ? "
echo

aws s3 sync s3://konvoy-bootstrap/bb-core/$FOLDER/ /bootstrap/bb-core/$FOLDER/
cp /bootstrap/scripts/bb/bigbang-upgrade-patch.sh /bootstrap/bb-core/$FOLDER/
cd ~
cd ~/tmp/$FOLDER
echo
echo -e "${yellow}Building package...${reset}"
echo
cp /bootstrap/bb-core/$FOLDER/* .

cd ..
tar -czvf bb-$FOLDER-updates.tar.gz $FOLDER
echo -e "${green}Finished creating $FOLDER packages to be sent to highside${reset}"
echo

echo -e "${yellow}Sending package to SIPR and JWICS...${reset}"
FILE2=bb-$FOLDER-updates.tar.gz
aws s3 cp $FILE2 s3://dcw-odin-both/ --acl bucket-owner-full-control
echo -e "${green}$FILE2 sent to SIPR and JWICS${reset}"
echo
echo -e "${blue}Files in BOTH tansfer bucket:${reset}"
aws s3 ls s3://dcw-odin-both/
echo

aws s3 cp $FILE2 s3://konvoy-bootstrap/bb-core/0-tar/
rm $FILE2
rm -rf ~/tmp/$FOLDER

echo
echo -e "${GREEN}=========================================================================================${NC}"
echo -e "${GREEN} :siren: BB $FOLDER pkg has been sent over transfer service to high side environments. ${NC}"
echo -e "${GREEN}=========================================================================================${NC}"

echo
echo -e "${green}Script completed${reset}"
echo
