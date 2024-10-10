#!/bin/bash
#set -x

######################################################################################################
# Script Name: load_podman_images.sh                                                                 #
# Description: This script will load bigbang docker images into local registry                       #
# Author     : Larry Sprouse                                                                         #
# Version    : 2.0.0                                                                                 #
######################################################################################################

##########################################################################################################
# Begin Get Variables
##########################################################################################################
today=$(date +"%m-%d-%Y-%H.%M.%S-%Z")
CNOW=$(date +"%Y-%m-%d-%H%M")
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

##########################################################################################################
#  Start Functions
##########################################################################################################

function yes_or_no {
    echo
    while true; do
       read -p "$* [y/n]: " yn
       echo
       case $yn in
            [Yy]*) echo  "Loading BB $FOLDER images.";
            echo;
            return 0  ;;
            [Nn]*) echo  "Skipping loading BB $FOLDER images"; return  1 ;;
        esac
    done
}

function validate_input () {
  echo
  echo "BB_VERSION: $BB_VERSION"

# Check if LOCAL ONLY TESTING
  if [ -z "$BB_VERSION" ];  then
      echo
      echo -e "${RED}!!! NOTE: Argument required to continue !!!${NC}"
      echo
      echo -e "${RED}You must supply 1 arguments with command. Eammple: ${NC}"
      echo -e "${YELLOW}   ./load_podman_images.sh <bb_version> ${NC}"
      echo
      exit
  fi
}


function load_images () {
    echo -e "${BLUE}Loading podman images for BB $BB_VERSION ${NC}"
    WORKING_DIR=/home/maintuser/image_import
    mkdir -p $WORKING_DIR
    mkdir -p /bootstrap/bb-core/$BB_VERSION
    echo -e "${BLUE}Syncing with s3 for BB version...${NC}"
    aws s3 sync s3://konvoy-bootstrap/bb-core/$BB_VERSION/ /bootstrap/bb-core/$BB_VERSION
    chmod -R 775 /bootstrap/bb-core/$BB_VERSION/
    echo -e "${BLUE}Extracting images.tar.gz...${NC}"
    tar -zxf $BUNDLE_PATH/images.tar.gz -C $WORKING_DIR
    cd $WORKING_DIR
    chmod -R 755 $WORKING_DIR
    sudo podman ps -a
    echo -e "${YELLOW}Launching Transient Registry...${NC}"
    container_id=$(sudo podman ps -a --format "{{.ID}}" --filter "name=transient-registry")
    CR=$(sudo podman ps -a | grep  "2.8.1")
    if [ -z "$container_id" ]; then
      echo -e "${YELLOW}Previous Transient does not exist${NC}"
      echo -e "${YELLOW}Building transient registry...${NC}"
      if [ -z "$CR" ]; then
        MESSAGE="Deployed to v2.8.2 Registry..."
        sudo podman run -d --name transient-registry -p 25000:5000 -v /home/maintuser/image_import/var/lib/registry:/var/lib/registry:z  registry1.dso.mil/ironbank/opensource/docker/registry-v2:2.8.2
      else
        MESSAGE="Deployed to v2.8.1 Registry..."
        sudo podman run -d --name transient-registry -p 25000:5000 -v /home/maintuser/image_import/var/lib/registry:/var/lib/registry:z  registry1.dso.mil/ironbank/opensource/docker/registry-v2:2.8.1
      fi
    else
      echo -e "${YELLOW}Previous Transient Registry Exists${NC}"
      sudo podman stop $container_id
      sleep 10
      sudo podman rm $container_id
      sleep 10
      echo -e "${YELLOW}Building transient registry...${NC}"
      if [ -z "$CR" ]; then
        MESSAGE="Deployed to v2.8.2 Registry..."
        sudo podman run -d --name transient-registry -p 25000:5000 -v /home/maintuser/image_import/var/lib/registry:/var/lib/registry:z  registry1.dso.mil/ironbank/opensource/docker/registry-v2:2.8.2
      else
        MESSAGE="Deployed to v2.8.1 Registry..."
        sudo podman run -d --name transient-registry -p 25000:5000 -v /home/maintuser/image_import/var/lib/registry:/var/lib/registry:z  registry1.dso.mil/ironbank/opensource/docker/registry-v2:2.8.1
      fi
    fi
      sudo podman ps -a
    sleep 5
    echo -e "${YELLOW}Synking...${NC}"
    cd $WORKING_DIR/var/lib/registry/
    ./synker push
    echo
    echo -e "${YELLOW}$MESSAGE${NC}"
    echo
    container_id=$(sudo podman ps -a --format "{{.ID}}" --filter "name=transient-registry")
    sudo podman stop $container_id
    sleep 5
    sudo podman rm $container_id
    cd
    rm -rf /home/maintuser/image_import
    echo -e "${GREEN}$BB_VERSION images loaded into Registry...${NC}"
}

##########################################################################################################
# End Functions
##########################################################################################################

##########################################################################################################
# Begin Main
##########################################################################################################

source /bootstrap/scripts/odin-logo.sh
BB_VERSION="$1"

# Check for valid input
validate_input

USER=`whoami`
if [ "$USER" != "maintuser" ]; then
  echo "Script must be run as the maintuser user"
  exit;
fi

echo
BUNDLE_PATH=/bootstrap/bb-core/$BB_VERSION
load_images


echo
echo -e "${GREEN}Script Completed${NC}"
echo

##########################################################################################################
# End Main
##########################################################################################################


