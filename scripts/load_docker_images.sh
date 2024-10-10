#!/bin/bash
#set -x

######################################################################################################
# Script Name: load_docker_images.sh                                                                 #
# Description: This script will load bigbang docker images into local registry                       #
# Author     : Larry Sprouse                                                                         #
# Version    : 1.0.0                                                                                 #
######################################################################################################

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

##########################################################################################################
# End Functions
##########################################################################################################

##########################################################################################################
# Begin Main
##########################################################################################################

#source /bootstrap/scripts/odin-logo.sh

USER=`whoami`
if [ "$USER" != "maintuser" ]; then
  echo "Script must be run as the maintuser user"
  exit;
fi

# Setup working directory
WORKING_DIR=/home/maintuser/image_import
mkdir -p $WORKING_DIR

# Get latest release folder
#FOLDER=`ls -lrth /bootstrap/bb-core/ | grep "^d" | awk '{ print $9}' | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -1`

echo
#ls -lrth /bootstrap/bb-core/ | grep "^d" | awk '{ print $9}'
aws s3 ls s3://konvoy-bootstrap/bb-core/ --recursive --human-readable --summarize | awk '{print $5}' | awk -F '/' '/\// {print $2}' | sort -u
echo
read -p "Select BB version to load : " FOLDER
mkdir -p /bootstrap/bb-core/$FOLDER
aws s3 sync s3://konvoy-bootstrap/bb-core/$FOLDER/ /bootstrap/bb-core/$FOLDER/
#if [ ! -d "/bootstrap/bb-core/$FOLDER" ] || [ -z "$FOLDER" ]; then
#   echo  "Incorrect folder choice... Aborting"
#   exit
#fi

echo
yes_or_no "Do you wish to load images for: $FOLDER ? "
BUNDLE_PATH=/bootstrap/bb-core/$FOLDER

echo "Extracting $BUNDLE_PATH/images.tar.gz"
tar -zxf $BUNDLE_PATH/images.tar.gz -C $WORKING_DIR
chmod -R u+x $WORKING_DIR
echo "Finished extracting $BUNDLE_PATH/images.tar.gz"

C_HOST=`cat $WORKING_DIR/var/lib/registry/synker.yaml | yq r - destination.registry.hostname`
C_PORT=`cat $WORKING_DIR/var/lib/registry/synker.yaml | yq r - destination.registry.port`

# Remove docker.io image references
sed -i '/.*docker\.io.*/d' $WORKING_DIR/var/lib/registry/synker.yaml

if [ "$C_HOST" != "p1-registry" ] ; then
 echo "Invalid Host $C_HOST"
 exit 1
fi

if [ "$C_PORT" != "5000" ] ; then
 echo "Invalid Port $C_PORT"
 exit 1
fi

echo $C_HOST $C_PORT

echo  "Launching Transient Registry"
docker run -d --cidfile /tmp/dtr.id -p 25000:5000 -v $WORKING_DIR/var/lib/registry:/var/lib/registry registry:2
sleep 5
echo "Synking "
cd $WORKING_DIR/var/lib/registry/
./synker push
DTR=`cat /tmp/dtr.id`
docker rm -f $DTR
rm /tmp/dtr.id
rm -rf $WORKING_DIR

echo
echo -e "${GREEN}Script Completed${NC}"
echo

##########################################################################################################
# End Main
##########################################################################################################
