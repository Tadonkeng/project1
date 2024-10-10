#!/bin/bash

###################################################################################################
# Script Name: import-bb-repos.sh                                                                 #
# Description: This script will import bigbang repos in prep for deployment/upgrade               #
# Author     : Larry Sprouse                                                                      #
# Version    : 1.0.0                                                                              #
###################################################################################################

## Changelog

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
CNOW=$(date +"%Y-%m")
today=$(date +"%m-%d-%Y-%H.%M.%S-%Z")
KONVOY_FOLDER=/home/maintuser/konvoy_v1.8.4

##########################################################################################################
#  Start Functions
##########################################################################################################

function yes_or_no {
    echo
    while true; do
       read -p "$* [y/n]: " yn
       echo
       case $yn in
            [Yy]*) echo -e "Deploying BB $FOLDER";
            echo ;
            return 0  ;;
            [Nn]*) echo -e "Aborted deployment"; exit ;;
        esac
    done
}

backupBigBang () {
    echo
    if [ ! -d ~/backups ]; then
        mkdir ~/backups
    fi
    #Get Version number
    if [ -f /home/git/big-bang/umbrella/chart/Chart.yaml ]; then
        rv=$(grep version ~/big-bang/umbrella/chart/Chart.yaml|awk '{print $2}')
        echo "Old BigBang Version: $rv"
        #Move old big-bang and repos (execute as git)
        if [ -d ~/big-bang ]; then
            echo -e "${yellow}Backing up big-bang directory...${reset}"
            mv ~/big-bang ~/backups/big-bang_v${rv}-${today} &> /dev/null
            while [ -d ~/big-bang ]
            do
              sleep 5
            done
        fi
        if [ -d ~/repos ]; then
            echo -e "${yellow}Backing up repos directory...${reset}"
            mv ~/repos ~/backups/repos_v${rv}-${today} &> /dev/null
            while [ -d ~/repos ]
            do
              sleep 5
            done
        fi
        else
        echo "No big-bang folder exists. Skipping backups."
        echo
    fi
    sleep 5
}

function pause () {
   echo -e "${YELLOW}Press enter to continue...${NC}"
   read -p "$*"
}

##########################################################################################################
# End Functions
##########################################################################################################

##########################################################################################################
# Begin Main
##########################################################################################################

#source /bootstrap/scripts/odin-logo.sh

USER=`whoami`

if [ "$USER" != "git" ]; then
  echo "Script must be run as the git user"
  exit;
fi

backupBigBang
rm -rf ~/big-bang

echo
#FOLDER=`ls -lrth /bootstrap/bb-core/ | grep "^d" | tail -1 | awk '{ print $9}'`
#FOLDER=`ls -lrth /bootstrap/bb-core/ | grep "^d" | awk '{ print $9}' | tail -n 1`
ls -lrth /bootstrap/bb-core/ | grep "^d" | awk '{ print $9}'
#aws s3 ls s3://konvoy-bootstrap/bb-core/ --recursive --human-readable --summarize | awk '{print $5}' | awk -F '/' '/\// {print $2}' | sort -u
echo
read -p "Select BB version to Deploy : " FOLDER
#mkdir -p /bootstrap/bb-core/$FOLDER
#aws s3 sync s3://konvoy-bootstrap/bb-core/$FOLDER/ /bootstrap/scripts/$FOLDER/
if [ ! -d "/bootstrap/bb-core/$FOLDER" ] || [ -z "$FOLDER" ]; then
   echo  "Folder choice does not exist... Aborting"
   exit
fi
yes_or_no "Do you wish to deploy BB: $FOLDER ? "

BUNDLE_PATH=/bootstrap/bb-core/$FOLDER
#echo "BUNDLE_PATH: $BUNDLE_PATH"
REPO_PATH=/home/git/repos

# clear /home/git/repos and extract repositories
echo "Clearing /home/git/repos/ folder"
rm -rf $REPO_PATH
#pause
tar -zxf $BUNDLE_PATH/repositories.tar.gz -C /home/git
echo "Extracting new repositories file to repos folder"
#pause

# grab values.yaml
FN=`ls $BUNDLE_PATH/bigbang* | sed 's%.*/%%' | sed s/\.tar\.gz// | sort | head -n 1`
#echo "FN: $FN"
echo "Clearing /tmp/umbrella folder"
rm -rf /tmp/umbrella
mkdir /tmp/umbrella
tar -C /tmp/umbrella -zxf $BUNDLE_PATH/$FN.tar.gz
echo "Extracting  $FN.tar.gz file to /tmp/umbrella folder"
#pause

mkdir -p /home/git/big-bang
cd /home/git/big-bang
#echo "REPO_PATH: $REPO_PATH"
cd $REPO_PATH
for f in *; do
    if [ -d $f ] ; then
	echo "Importing $f"
        BASE=`echo $f`
        echo "BASE: $BASE"
        #continue
        #pause
        if [ ! -d /home/git/big-bang/$BASE ]; then
            BRANCH=`cat /tmp/umbrella/$FN/chart/values.yaml | grep -A 3 "repo.*$BASE\.git" | grep "tag" | tail -1 | awk '{ print $2}' | sed 's/"//g'`
            echo "BRANCH: $BRANCH"
            #pause
        fi
        echo
	    if [ ! -d /home/git/big-bang/$BASE ] ; then
              cd /home/git/big-bang
              echo -e "${GREEN}Cloning into big-bang...${NC}"
	      git clone ssh://git@$(hostname -i)/home/git/repos/$f
              cd $f
              echo -e "${GREEN}cd to folder $f${NC}"
              git checkout tags/$BRANCH
              git branch odin
              git checkout odin
              echo "############ Checkout ODIN Branch ###############"
              #pause
	    else
              echo -e "${RED}Dont expect to ever see this since cleared bigbang - can probably delete this else section${NC}"
              pause
              cd /home/git/repos/$BASE
              MT=`git describe --tags $BRANCH`
              cd /home/git/big-bang/$BASE
	      git fetch --tags origin
              git merge $MT
        fi
        cd $REPO_PATH
    fi
done

echo "moving umbrella folders from /tmp/umbrella/bigbang/umbrella to /git/repos/umbrella"
FN2=`find /tmp/umbrella -maxdepth 1 -mindepth 1 -type d`
#mv $FN2 /home/git/repos/umbrella

if [ ! -d /home/git/big-bang/umbrella ]; then
   echo "Initializing bigbang/umbrella repo"
   #mkdir /home/git/big-bang/umbrella
   #cp -a /home/git/repos/umbrella /home/git/big-bang/
   mv $FN2 /home/git/big-bang/umbrella
   cd /home/git/big-bang/umbrella
   git init .
   git checkout -b master
   git add .
   git commit -m 'initial import'
   git init ~/repos/umbrella/.git --bare
   git remote add master git@$(hostname -i):/home/git/repos/umbrella/.git
   git remote add origin git@$(hostname -i):/home/git/repos/umbrella/.git
   git push master master
fi

cd /home/git/big-bang
echo "Checking for conflicts"
for  f in * ; do
 #echo -e "${YELLOW}app: $f${NC}"
 if [ -d $f ] ; then
  cd $f
  git status | grep "conflict" > /dev/null
  if [ $?  -eq 0 ] ; then
      echo "${RED}Merge conflict detected in $f${NC}"
  fi
  cd ..
 fi
done

echo
echo -e "${GREEN}Script Completed${NC}"
echo

##########################################################################################################
# End Main
##########################################################################################################

