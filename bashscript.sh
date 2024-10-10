#!/bin/bash

####################################################################################################################################
# Script Name: app-synker-update_v1.15.0.sh
# Description: This script will create a synker packages for mission apps, save to aws and transfer to hight side envireonments
# Author     : Larry Sprouse
# Version    : 1.15.0
# Last Updated : 9/06/22
####################################################################################################################################

##########################################################################################################
#  Changelog
##########################################################################################################
# v1.3.0
# changed location and name of daily package counts filename
# changed log to logs/synker-$CNOW.log
# v1.4.0
# added counter for Packages sent to SIPR and JWICS per month
# v1.6.0
# removed s3 folders for date
# v1.7.0
# added complete option section for full packages
# v1.8.0
# Added and seperated Mission apps based on IL
# v1.9.0
# Added Virtualitics
# Alphabetized apps and renumbered
# changed synker name built
# changed tar.gz created file name
# v1.10.0
# Adding individual app counts
# v1.11.0
# Adding individual app counts
# v1.12.0
# Fixing Combined monthly app counts
# v1.13.0
# Adding thirdparty apps
# Added other apps feature
# v1.14.0
# Changed all references from VI2E to ODIN
# v1.15.0
# Added auto transfers and using both bucket to send to high sides now.
# v1.15.1 - Placed all options in alphabetical order
##########################################################################################################
#  Variables
##########################################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
NOW=$(date +"%Y-%m-%d")
CNOW=$(date +"%Y-%m")
cwd=$(pwd)
FOLDER=$cwd
BUCKET=sipr-mission-bootstrap
ADD_COUNT=1
APP="none"
APP2="count"

######### COMMENT AFTER TESTING ########
#echo  -e "${RED}  COMMENTED FOR TESTING - REMOVE IN PRODUCTION${NC}"
#NOW=2022-11-01
#CNOW=2022-11
######### COMMENT AFTER TESTING ########

declare -a APP_IMAGES

##########################################################################################################
#  Begin Functions
##########################################################################################################

getApp () {
  # STEPS TO COMPLETE IF ADDING NEW APP
  # BE SURE TO UPDATE IF NEW APP_ARRAY IN MAIN PART OF SCRIPT IF NEW APP ADDED
  # IF THIS ARRAY IS NOT UPDATED, METRICS WILL NOT BE COLLECTED
  # THEN UPDATE MENU AND CASE
  # CREATE CSV FOR  APP
  while true; do
    echo
    echo -e "${CYAN} ##########################################"
    echo -e "${CYAN} #   MISSION APP SYNKER PACKAGE BUILDER   #"
    echo -e "${CYAN} ##########################################"
    echo
    echo -e "${GREEN} ################ IL2 #################${NC}"
    echo
    echo -e "${GREEN}          10)   AFRICOM-J2${NC}"
    #echo -e "${GREEN}           1)   BATTLEDRILL (Deprecated)${NC}"
    echo -e "${GREEN}           1)   C2D2${NC}"
    #echo -e "${GREEN}           2)   C3PO (Deprecated)${NC}"
    #echo -e "${GREEN}           3)   FSCA-BASALT (Deprecated)${NC}"
    echo -e "${GREEN}           3)   FUELAI${NC}"
    echo -e "${GREEN}          15)   IDEX${NC}"
    echo -e "${GREEN}           2)   INFINITYAI${NC}"
    echo -e "${GREEN}           4)   JAIMI${NC}"
    echo -e "${GREEN}           19)  JFAC${NC}"
    #echo -e "${GREEN}           5)   JPRA-PRIDS (Deprecated)${NC}"
    #echo -e "${GREEN}           6)   LEARNTOWIN (Deprecated)${NC}"
    echo -e "${GREEN}           7)   PANTHEON (KRAKEN)${NC}"
    #echo -e "${GREEN}           8)   RDPL (Deprecated)${NC}"
    echo -e "${GREEN}           9)   RESPOND${NC}"
    echo -e "${GREEN}          11)   SPACECOCKPIT${NC}"
    echo -e "${GREEN}          16)   TARDYS3${NC}"
    echo -e "${GREEN}          18)   UDOP${NC}"
    echo -e "${GREEN}          17)   USTRANSCOM-TFA${NC}"
    #echo -e "${GREEN}          12)   VIRTUALITICS (VET) (Deprecated)${NC}"
    echo -e "${GREEN}          13)   WIDOW${NC}"
    echo -e "${GREEN}          14)   WINGMANAI${NC}"
    echo
    echo -e "${PURPLE} ################ IL4 #################${NC}"
    echo
    echo -e "${PURPLE}          20)   ABMS-LINK16CTC${NC}"
    echo -e "${PURPLE}          35)   AFTIMES${NC}"
    #echo -e "${PURPLE}          21)   ARAKNID (Deprecated)${NC}"
    echo -e "${PURPLE}          22)   COLE${NC}"
    echo -e "${PURPLE}          23)   DARTS${NC}"
    echo -e "${PURPLE}          32)   DECON+${NC}"
    echo -e "${PURPLE}          24)   DRAC${NC}"
    echo -e "${PURPLE}          25)   GENESIS${NC}"
    echo -e "${PURPLE}          26)   LOCUTUS${NC}"
    echo -e "${PURPLE}          33)   IMPACT${NC}"
    echo -e "${PURPLE}          27)   JADII-UI${NC}"
    echo -e "${PURPLE}          28)   KRAKEN (JADII KRAKEN-CORE)${NC}"
    echo -e "${PURPLE}          31)   RADIANCE${NC}"
    echo -e "${PURPLE}          29)   RIPSAW${NC}"
    echo -e "${PURPLE}          34)   SPACE-WIKI${NC}"
    echo -e "${PURPLE}          30)   TIGER-RANCH (PEDESTAL)${NC}"
    echo
    echo -e "${BLUE} ################ IL5 #################${NC}"
    echo
    echo -e "${BLUE}          60)   RHOMBUS-GUARDIAN (COMPETITION)${NC}"
    echo -e "${BLUE}          61)   RHOMBUS-GUARDIAN (DAF-PPBE)${NC}"
    echo -e "${BLUE}          62)   RHOMBUS-GUARDIAN (FORCE)${NC}"
    echo -e "${BLUE}          63)   RHOMBUS-GUARDIAN (SDA)${NC}"
    echo -e "${BLUE}          64)   MASE/SFCAP${NC}"
    echo
    echo -e "${PURPLE} ################ MISC #################${NC}"
    echo
    echo -e "${PURPLE}          77)   CLAMAV${NC}"
    echo -e "${PURPLE}          73)   Confluence${NC}"
    echo -e "${PURPLE}          78)   Keycloak${NC}"
    echo -e "${PURPLE}          74)   Jira${NC}"
    echo -e "${PURPLE}          75)   Fluentd${NC}"
    echo -e "${PURPLE}          76)   Fortify SSC${NC}"
    echo -e "${PURPLE}          99)   Other${NC}"
    echo -e "${PURPLE}          71)   Velero${NC}"
    echo -e "${PURPLE}          72)   Velero-plugin-for-aws${NC}"
    echo
    echo -e -n "${YELLOW}      Select Mission to update ? ${NC}"
    read CHOICE
    echo
    case $CHOICE in
      #1 ) ODIN_TRANSFER=3;APP=battledrill; APP_VALUE=battledrill.csv; break;;
      1 ) ODIN_TRANSFER=3;APP=c2d2; APP_VALUE=c2d2.csv; break;;
      2 ) ODIN_TRANSFER=3;APP=infinityai; APP_VALUE=infinityai; break;;
      #2 ) ODIN_TRANSFER=3;APP=c3po; APP_VALUE=c3po.csv; break;;
      #3 ) ODIN_TRANSFER=3;APP=fsca-basalt; APP_VALUE=fsca-basalt.csv; break;;
      3 ) ODIN_TRANSFER=3;APP=fuelai; APP_VALUE=fuelai.csv; break;;
      4 ) ODIN_TRANSFER=3;APP=jaimi; APP_VALUE=jaimi.csv; break;;
      #5 ) ODIN_TRANSFER=3;APP=jpra-prids; APP_VALUE=jpra-prids.csv; break;;
      #6 ) ODIN_TRANSFER=1;APP=learntowin; APP_VALUE=learntowin.csv; break;;
      7 ) ODIN_TRANSFER=1;APP=pantheon; APP_VALUE=pantheon.csv; break;;
      #8 ) ODIN_TRANSFER=2;APP=rdpl; APP_VALUE=rdpl.csv; break;;
      9 ) ODIN_TRANSFER=3;APP=respond; APP_VALUE=respond.csv; break;;
     10 ) ODIN_TRANSFER=3;APP=africom-j2; APP_VALUE=africom-j2.csv; break;;
     11 ) ODIN_TRANSFER=1;APP=saber; APP_VALUE=spacecockpit.csv; break;;
     #12 ) ODIN_TRANSFER=1;APP=virtualitics; APP_VALUE=virtualitics.csv; break;;
     13 ) ODIN_TRANSFER=3;APP=widow; APP_VALUE=widow.csv; break;;
     14 ) ODIN_TRANSFER=1;APP=wingmanai; APP_VALUE=wingmanai.csv; break;;
     15 ) ODIN_TRANSFER=1;APP=idex; APP_VALUE=idex.csv; break;;
     16 ) ODIN_TRANSFER=2;APP=tardys3; APP_VALUE=tardys3.csv; break;;
     17 ) ODIN_TRANSFER=2;APP=ustranscom-tfa; APP_VALUE=ustranscom-tfa.csv; break;;
     18 ) ODIN_TRANSFER=2;APP=udop; APP_VALUE=udop.csv; break;;
     19 ) ODIN_TRANSFER=2;APP=jfac; APP_VALUE=jfac.csv; break;;

     20 ) ODIN_TRANSFER=1;APP=abms-link16ctc; APP_VALUE=abms-link16ctc.csv; break;;
     #21 ) ODIN_TRANSFER=1;APP=araknid; APP_VALUE=araknid.csv; break;;
     22 ) ODIN_TRANSFER=3;APP=cole; APP_VALUE=cole.csv; break;;
     23 ) ODIN_TRANSFER=1;APP=darts; APP_VALUE=darts.csv; break;;
     24 ) ODIN_TRANSFER=1;APP=drac; APP_VALUE=drac.csv; break;;
     25 ) ODIN_TRANSFER=1;APP=genesis; APP_VALUE=genesis.csv; break;;
     26 ) ODIN_TRANSFER=1;APP=locutus; APP_VALUE=locutus.csv; break;;
     27 ) ODIN_TRANSFER=2;APP=jadii-ui; APP_VALUE=jadii-ui.csv; break;;
     28 ) ODIN_TRANSFER=2;APP=kraken; APP_VALUE=kraken.csv; break;;
     29 ) ODIN_TRANSFER=2;APP=ripsaw; APP_VALUE=ripsaw.csv; break;;
     30 ) ODIN_TRANSFER=2;APP=tiger-ranch; APP_VALUE=tiger-ranch.csv; break;;
     31 ) ODIN_TRANSFER=2;APP=radiance; APP_VALUE=radiance.csv; break;;
     32 ) ODIN_TRANSFER=1;APP=decon; APP_VALUE=decon.csv; break;;
     33 ) ODIN_TRANSFER=2;APP=impact; APP_VALUE=impact; break;;
     34 ) ODIN_TRANSFER=2;APP=space-wiki APP_VALUE=space-wiki; break;;
     35 ) ODIN_TRANSFER=2;APP=aftimes APP_VALUE=aftimes.csv; break;;

     60 ) ODIN_TRANSFER=2;APP=competition; APP_VALUE=competition.csv; break;;
     61 ) ODIN_TRANSFER=2;APP=daf-ppbe; APP_VALUE=daf-ppbe.csv; break;;
     62 ) ODIN_TRANSFER=2;APP=force; APP_VALUE=force.csv; break;;
     63 ) ODIN_TRANSFER=2;APP=sda; APP_VALUE=sda.csv; break;;
     64 ) ODIN_TRANSFER=2;APP=sfcap; APP_VALUE=sfcap.csv; break;;

     71 ) ODIN_TRANSFER=3;APP=velero; APP_VALUE=velero.csv; APP2="nocount"; break;;
     72 ) ODIN_TRANSFER=3;APP=velero-plugin-for-aws; APP_VALUE=velero-plugin-for-aws.csv; APP2="nocount"; break;;
     73 ) ODIN_TRANSFER=3;APP=Confluence; APP_VALUE=confluence.csv; APP2="nocount"; break;;
     74 ) ODIN_TRANSFER=3;APP=Jira; APP_VALUE=jira.csv; APP2="nocount"; break;;
     75 ) ODIN_TRANSFER=3;APP=fluentd; APP_VALUE=fluentd.csv; APP2="nocount"; break;;
     76 ) ODIN_TRANSFER=3;APP=fortifyssc; APP_VALUE=fortifyssc.csv; APP2="nocount"; break;;
     77 ) ODIN_TRANSFER=3;APP=clamav; APP_VALUE=clamav.csv; APP2="nocount"; break;;
     78 ) ODIN_TRANSFER=3;APP=keycloak; APP_VALUE=keycloak; APP2="nocount"; break;;
     99 ) ODIN_TRANSFER=3;APP=other; APP_VALUE=misc.csv; break;;
      * ) echo -e "${RED}Exiting since no selection was made ${NC}"; exit;;
    esac
  done
  return 0
}

modifyAppCSV () {
  vim $FOLDER/csv/$APP_VALUE
  return 0
}

modifySynkerYaml () {
  oldIFS=$IFS
  echo
  echo -e "${YELLOW}Creating new $APP package synker containing the following images:${NC}" | tee -a logs/synker-$CNOW.log
  echo
  inc=0
  while IFS=, read -r replace image
  do
    if [ ! -z "$replace" ]; then
      nreplace=$(echo "${replace}"|sed 's/^ *//g'|sed 's/ *$//g')
      nimage=$(echo "${image}"|sed 's/^ *//g'|sed 's/ *$//g')
      APPVERSION="${nimage##*/}"
      #echo $APPVERSION
      if [ $nreplace = 'y' ]; then
        echo  -e "${GREEN}  $nimage ${NC}"
        #echo  -e "${GREEN}  $APPVERSION ${NC}" | tee -a logs/synker-$CNOW.log
        APP_IMAGES+=($APPVERSION)
        #echo $APP_IMAGE
        # SYNKER BOX REQUIRED CHANGES
        ## yq version 3.4.1 - For synker Box
        ######### REMOVE COMMENTS AFTER TESTING ########
        yq w -i "$FOLDER/synker.yaml" source.images[+] "$nimage"
        ######### REMOVE COMMENTS AFTER TESTING ########
        ## yq version 4.21.1 - For MAC OS
        ######### ADD COMMENTS AFTER TESTING ########
        #echo  -e "${RED}  YQ Setup for MAC OS${NC}"
        #pathEnv=".source.images[${inc}]" myEnv=$nimage yq -i 'eval(env(pathEnv)) = env(myEnv)' synker.yaml
        ######### ADD COMMENTS AFTER TESTING ########
        inc=$((inc+1))
        #echo $inc
      fi
    else
      break
    fi
  done < <(grep -v "^#\|^$" $FOLDER/csv/$APP_VALUE)
  echo
  IFS=$oldIFS
  echo
  echo -e "${BLUE}=============== synker.yaml to build ==================";
  echo -e "=======================================================";
  cat $FOLDER/synker.yaml;
  echo -e "=======================================================${NC}";
  echo
}

function yes_or_no_process {
    echo
    #NOW=$(date +"%Y-%m-%d")
    COUNTFILECHECK="$FOLDER/count/daily-$APP.count"
    #echo "COUNTFILECHECK: $COUNTFILECHECK"
    if [ -f "$COUNTFILECHECK" ]; then
      #echo -e "${RED} File Exists${NC}"
      FDATE=$(head -n 1 $COUNTFILECHECK)
      if [ ! $FDATE = $NOW ]; then
        #echo -e "${RED} Different Day${NC}"
        echo $NOW > $COUNTFILECHECK
        COUNT=1
      else
        #echo -e "${RED} File Does Not Exist${NC}"
        COUNT=$(wc -l < $COUNTFILECHECK)
        COUNT=$(cat $COUNTFILECHECK | awk 'END{print NR}')
      fi
    else
      echo $NOW > $COUNTFILECHECK
      COUNT=1
    fi
    ######### ADD COMMENT AFTER TESTING ########
    #echo -e "${RED} COUNT= :$COUNT: ${NC}"
    ######### ADD COMMENT AFTER TESTING ########
    while true; do
        read -p "$* [y/n]: " yn
        case $yn in
            [Yy]*) echo;
            ######### REMOVE COMMENTS AFTER TESTING ########
            yes_or_no_complete "Is this a Complete Package ? "
            ######### REMOVE COMMENTS AFTER TESTING ########
            ######### ADD COMMENTS AFTER TESTING ########
            #echo  -e "${RED}  UNCOMMENTED FOR TESTING - REMOVE IN PRODUCTION${NC}"
            #COMPLETE="no"
            ######### ADD COMMENTS AFTER TESTING ########
            echo -e "${YELLOW}Docker Build in progress for $APP...${NC}" | tee -a logs/synker-$CNOW.log;
            echo
            NAME=$APP
            if [ $COMPLETE = "yes" ]; then
              FILE=FULL.synker.$APP.$NOW-$COUNT.tar.gz;
            else
              FILE=synker.$APP.$NOW-$COUNT.tar.gz;
            fi
            ###### If proxy needed
            #docker build --build-arg http_proxy=http://internal-transit-o-relbprox-18258a4c7zu9g-1035696995.us-gov-west-1.elb.amazonaws.com:3128/ --build-arg https_proxy=http://internal-transit-o-relbprox-18258a4c7zu9g-1035696995.us-gov-west-1.elb.amazonaws.com:3128/ . -f sync.Dockerfile -t synker:$NAME;
            ###### if no proxy
            ######### REMOVE COMMENTS AFTER TESTING ########
            #echo  -e "${RED}  UNCOMMENTED  FOR TESTING - REMOVE IN PRODUCTION${NC}"
            docker build . -f sync.Dockerfile -t synker:$NAME  | tee -a logs/synker-$CNOW.log;
            ######### REMOVE COMMENTS AFTER TESTING ########
            echo
            echo -e "${GREEN}Docker Build complete...${NC}" | tee -a logs/synker-$CNOW.log;
            echo
            echo -e "${YELLOW}Docker Save in progess...${NC}" | tee -a logs/synker-$CNOW.log;
            ######### REMOVE COMMENTS AFTER TESTING ########
            #echo  -e "${RED}  UNCOMMENTED FOR TESTING - REMOVE IN PRODUCTION${NC}"
            docker save synker:$NAME | gzip > $FILE | tee -a logs/synker-$CNOW.log;
            ######### REMOVE COMMENTS AFTER TESTING ########
            ######### ADD COMMENTS AFTER TESTING ########
            #echo  -e "${RED}  UNCOMMENTED FOR TESTING - REMOVE IN PRODUCTION${NC}"
            #touch $FILE
            ######### ADD COMMENTS AFTER TESTING ########
            echo -e "${GREEN}Docker Save complete...${NC}" | tee -a logs/synker-$CNOW.log;
            echo
            ls -lrth | grep $APP*.gz
            return 0  ;;
            [Nn]*) echo -e "${RED}Aborted Build ${NC}" | tee -a logs/synker-$CNOW.log; echo | tee -a logs/synker-$CNOW.log; exit; return  1 ;;
        esac
    done
    FLAG=""
    echo -e "${GREEN}Package Build complete...${NC}" | tee -a logs/synker-$CNOW.log;
    return 0
}

function yes_or_no_complete {
    echo
    while true; do
       read -p "$* [y/n]: " yn
       echo
       case $yn in
            [Yy]*) echo -e "${YELLOW}Saving $APP as a complete package ${NC}" | tee -a logs/synker-$CNOW.log;
            COMPLETE="yes"
            return 0  ;;
            [Nn]*) echo;
            COMPLETE="no";
            return 1 ;;
        esac
    done
}

function yes_or_no_transfer_UC2S {
    echo
    SIPRMONTHLYAPPCOUNTCHECK="$FOLDER/count/monthly-sipr-$APP.count"
    JWICSMONTHLYAPPCOUNTCHECK="$FOLDER/count/monthly-jwics-$APP.count"
    TOTALMONTHLYAPPCOUNT="$FOLDER/count/monthly-total-$APP.count"
    while true; do
       read -p "$* [y/n]: " yn
       echo
       case $yn in
            [Yy]*) echo -e "${YELLOW}Saving $APP package to UC2S S3 Bucket... ${NC}";
            echo -e "${YELLOW}Transfer to UC2S S3 Bucket in progress...${NC}" | tee -a logs/synker-$CNOW.log;
            #echo -e "${RED}Testing... No Actual Transfer taking place...${NC}"
            ######### REMOVE COMMENTS AFTER TESTING ########
            #echo  -e "${RED}  UNCOMMENTED FOR TESTING - REMOVE IN PRODUCTION${NC}"
            aws s3 cp $FILE s3://$BUCKET/mission-apps/$APP/ | tee -a logs/synker-$CNOW.log;
            ######### REMOVE COMMENTS AFTER TESTING ########
            FLAG="set"
            echo $COUNT >> $COUNTFILECHECK
            echo -e "${GREEN}Transfer to UC2S S3 Bucket complete...${NC}" | tee -a logs/synker-$CNOW.log;
            return 0  ;;
            [Nn]*) echo -e "${RED}Aborted transfer to UC2S S3 Bucket ${NC}" | tee -a logs/synker-$CNOW.log; ODIN_TRANSFER=0; echo  | tee -a logs/synker-$CNOW.log; exit; return 1 ;;
        esac
    done
}

function yes_or_no_transfer_manual {
    echo
    while true; do
       read -p "$* [y/n]: " yn
       echo
       case $yn in
            [Yy]*) echo -e "${YELLOW}Option selected to choose transfer destination${NC}" | tee -a logs/synker-$CNOW.log;
            ODIN_TRANSFER=4
            return 0  ;;
            [Nn]*) echo;
            echo -e "${YELLOW}Option selected to allow automated transfer destination${NC}" | tee -a logs/synker-$CNOW.log;
            return 1 ;;
        esac
    done
}

function transfer_option_menu () {
  while true; do
    echo
    echo -e "${GREEN} ######### Transfer Option  #################${NC}"
    echo
    echo -e "${GREEN}           1)   BOTH${NC}"
    echo -e "${GREEN}           2)   SIPR${NC}"
    echo -e "${GREEN}           3)   JWICS${NC}"
    echo
    echo -e -n "${YELLOW}      Select Transfer Destination? ${NC}"
    read CHOICE
    echo
    case $CHOICE in
      1 ) ODIN_TRANSFER=3; break;;
      2 ) ODIN_TRANSFER=1; break;;
      3 ) ODIN_TRANSFER=2; break;;
      * ) echo -e "${RED}Exiting since no selection was made ${NC}"; exit;;
    esac
  done
  return 0
}

function transfer_sipr {
    echo
    echo -e "${YELLOW}Sending $APP package over ODIN Transfer Service to SIPR... ${NC}";
    echo -e "${YELLOW}Transfer to SC2S in progress...${NC}" | tee -a logs/synker-$CNOW.log;
    #echo -e "${RED}Testing... No Actual Transfer taking place...${NC}"
    ######### REMOVE COMMENTS AFTER TESTING ########
    #echo  -e "${RED}  UNCOMMENTED FOR TESTING - REMOVE IN PRODUCTION${NC}"
    aws s3 cp s3://$BUCKET/mission-apps/$APP/$FILE s3://dcw-odin-sc2s/ --acl bucket-owner-full-control | tee -a logs/synker-$CNOW.log;
    ########## REMOVE COMMENTS AFTER TESTING ########
    if [ "$ADD_COUNT" == 1 ]; then
       sipr_count
       echo $COUNT >> "${SIPRMONTHLYCOUNTCHECK}"
    fi
    sipr_app_count
    echo $SAPPCOUNT >> "${SIPRMONTHLYAPPCOUNTCHECK}"
    echo -e "${GREEN}Transfer to SC2S complete...${NC}" | tee -a logs/synker-$CNOW.log;
    return 0
}

function transfer_jwics {
    echo
    echo -e "${YELLOW}Sending $APP package over ODIN Transfer Service to JWICS... ${NC}";
    echo -e "${YELLOW}Transfer to TC2S in progress...${NC}" | tee -a logs/synker-$CNOW.log;
    #echo -e "${RED}Testing... No Actual Transfer taking place...${NC}"
    ######### REMOVE COMMENTS AFTER TESTING ########
    #echo  -e "${RED}  UNCOMMENTED FOR TESTING - REMOVE IN PRODUCTION${NC}"
    aws s3 cp s3://$BUCKET/mission-apps/$APP/$FILE s3://dcw-odin-tc2s/ --acl bucket-owner-full-control | tee -a logs/synker-$CNOW.log;
    ########## REMOVE COMMENTS AFTER TESTING ########
    if [ "$ADD_COUNT" == 1 ]; then
       jwics_count
       echo $COUNT >> "${JWICSMONTHLYCOUNTCHECK}"
    fi
    jwics_app_count
    echo $TAPPCOUNT >> "${JWICSMONTHLYAPPCOUNTCHECK}"
    echo -e "${GREEN}Transfer to TC2S complete...${NC}" | tee -a logs/synker-$CNOW.log;
    return 0
}

function transfer_both () {
    echo
    echo -e "${YELLOW}Sending $APP package over ODIN Transfer Service to both SIPR and JWICS... ${NC}";
    echo -e "${YELLOW}Transfer to SC2S and TC2S in progress...${NC}" | tee -a logs/synker-$CNOW.log;
    #echo -e "${RED}Testing... No Actual Transfer taking place...${NC}"
    ######### REMOVE COMMENTS AFTER TESTING ########
    #echo  -e "${RED}  UNCOMMENTED FOR TESTING - REMOVE IN PRODUCTION${NC}"
    aws s3 cp s3://$BUCKET/mission-apps/$APP/$FILE s3://dcw-odin-both/ --acl bucket-owner-full-control | tee -a logs/synker-$CNOW.log;
    ########## REMOVE COMMENTS AFTER TESTING ########
    if [ "$ADD_COUNT" == 1 ]; then
       sipr_count
       jwics_count
       echo $COUNT >> "${SIPRMONTHLYCOUNTCHECK}"
       echo $COUNT >> "${JWICSMONTHLYCOUNTCHECK}"
    fi
    sipr_app_count
    jwics_app_count
    echo $SAPPCOUNT >> "${SIPRMONTHLYAPPCOUNTCHECK}"
    echo $TAPPCOUNT >> "${JWICSMONTHLYAPPCOUNTCHECK}"
    echo -e "${GREEN}Transfer to SC2S and TC2S complete...${NC}" | tee -a logs/synker-$CNOW.log;
    return 0
}

function check_new_month () {
  echo  -e "${YELLOW}  Checking if new month...${NC}"
  sleep 2
  RESETMONTH=0
  SCOUNT=0
  TCOUNT=0
  SIPRMONTHLYCOUNTCHECK="$FOLDER/count/monthly-temp-sipr.count"
  JWICSMONTHLYCOUNTCHECK="$FOLDER/count/monthly-temp-jwics.count"
  TOTALMONTHLYCOUNT="$FOLDER/count/monthly-total.count"
  iSIPRMONTHLYAPPCOUNTCHECK="$FOLDER/count/monthly-sipr-$APP.count"
  JWICSMONTHLYAPPCOUNTCHECK="$FOLDER/count/monthly-jwics-$APP.count"
  TOTALMONTHLYAPPCOUNT="$FOLDER/count/monthly-total-$APP.count"
  TOTALCOMBINEDAPPMONTHLYCOUNT="$FOLDER/count/monthly-combined-total-app.count"
  if [ -f "$SIPRMONTHLYCOUNTCHECK" ]; then
    FDATE=$(head -n 1 $SIPRMONTHLYCOUNTCHECK)
    ######### ADD COMMENTS AFTER TESTING ########
    #echo  -e "${RED}  SIPR TEMP EXISTS${NC}"
    #echo  -e "${RED}  UNCOMMENTED FOR TESTING - REMOVE IN PRODUCTION${NC}"
    #echo "FDATE and CNOW - $FDATE , $CNOW"
    ######### ADD COMMENTS AFTER TESTING ########
    if [ ! $FDATE = $CNOW ]; then
        RESETMONTH=1
        SCOUNT=$(($(wc -l < $SIPRMONTHLYCOUNTCHECK)-1))
        #RESETSIPR=1
        if [ -f "$JWICSMONTHLYCOUNTCHECK" ]; then
          TCOUNT=$(($(wc -l < $JWICSMONTHLYCOUNTCHECK)-1))
          #RESETJWICS=1
        else
          TCOUNT=0
        fi
    fi
  else
    if [ -f "$JWICSMONTHLYCOUNTCHECK" ]; then
      FDATE=$(head -n 1 $JWICSMONTHLYCOUNTCHECK)
      ######### ADD COMMENTS AFTER TESTING ########
      #echo  -e "${RED}  JWICS TEMP EXISTS${NC}"
      #echo  -e "${RED}  UNCOMMENTED FOR TESTING - REMOVE IN PRODUCTION${NC}"
      #echo "  FDATE and CNOW - $FDATE , $CNOW"
      ######### ADD COMMENTS AFTER TESTING ########
      if [ ! $FDATE = $CNOW ]; then
        RESETMONTH=1
        TCOUNT=$(($(wc -l < $JWICSMONTHLYCOUNTCHECK)-1))
        #RESETJWICS=1
        if [ -f "$SIPRMONTHLYCOUNTCHECK" ]; then
          SCOUNT=$(($(wc -l < $SIPRMONTHLYCOUNTCHECK)-1))
          #RESETSIPR=1
        else
          SCOUNT=0
        fi
      fi
    fi
    echo  -e "${YELLOW} SCOUNT: $SCOUNT${NC}"
    echo  -e "${YELLOW} TCOUNT: $TCOUNT${NC}"
  fi

  echo  -e "${YELLOW}  Testing Month reset: $RESETMONTH${NC}"
  if [[ $RESETMONTH == 1 ]]; then
    echo "Total Overall Monthly ODIN Transfers" >> $TOTALMONTHLYCOUNT
    echo "----------------------------------------" >> $TOTALMONTHLYCOUNT
    echo "${FDATE}      SIPR:      ${SCOUNT}" >> $TOTALMONTHLYCOUNT
    echo "${FDATE}      JWICS:     ${TCOUNT}" >> $TOTALMONTHLYCOUNT
    echo "----------------------------------------" >> $TOTALMONTHLYCOUNT
    echo “remove temp monthly files”
    rm $JWICSMONTHLYCOUNTCHECK
    rm $SIPRMONTHLYCOUNTCHECK
    # If not removed, it will append all months
    rm $TOTALCOMBINEDAPPMONTHLYCOUNT
    # reset and total all apps counts
    for appcountreset in  ${APP_ARRAY[@]};
    do
      SIPRMONTHLYAPPCOUNTCHECK="$FOLDER/count/monthly-sipr-$appcountreset.count"
      JWICSMONTHLYAPPCOUNTCHECK="$FOLDER/count/monthly-jwics-$appcountreset.count"
      TOTALMONTHLYAPPCOUNT="$FOLDER/count/monthly-total-$appcountreset.count"
      if [ ! -f "$TOTALMONTHLYAPPCOUNT" ]; then
        echo "" > $TOTALMONTHLYAPPCOUNT
        #echo "Total Monthly ODIN Transfers - $appcountreset" >> $TOTALMONTHLYAPPCOUNT
      fi
      ######### ADD COMMENTS AFTER TESTING ########
      #echo  -e "${RED}  UNCOMMENTED FOR TESTING - REMOVE IN PRODUCTION${NC}"
      ######### ADD COMMENTS AFTER TESTING ########
      echo "Total Monthly ODIN Transfers - $appcountreset" >> $TOTALMONTHLYAPPCOUNT
      echo "$appcountreset" >> $TOTALCOMBINEDAPPMONTHLYCOUNT
      NEXTUCAPP=$(echo $appcountreset| tr '[:lower:]' '[:upper:]')
      echo "Resetting $appcountreset monthly counts"
      sleep 1
      if [ ! -f "$SIPRMONTHLYAPPCOUNTCHECK" ]; then
        SAPPCOUNT=0
      else
        SAPPCOUNT=$(($(wc -l < $SIPRMONTHLYAPPCOUNTCHECK)-1))
        rm $SIPRMONTHLYAPPCOUNTCHECK
      fi
      if [ ! -f "$JWICSMONTHLYAPPCOUNTCHECK" ]; then
        TAPPCOUNT=0
      else
        TAPPCOUNT=$(($(wc -l < $JWICSMONTHLYAPPCOUNTCHECK)-1))
        rm $JWICSMONTHLYAPPCOUNTCHECK
      fi
      TOTALCOUNTAPP="$FOLDER/count/monthly-total-$appcountreset.count"
      if [ ! -f "$TOTALCOUNTAPP" ]; then
        echo "" > $TOTALCOUNTAPP
        echo "NEXTUCAP: Uppercase APP Name that is supposed to be added to file: $NEXTUCAPP"
        echo "    Total ODIN App: $NEXTUCAPP Transfers Monthly" >> $TOTALCOUNTAPP
        echo "    Total ODIN App: $NEXTUCAPP Transfers Monthly" >> $TOTALMONTHLYAPPCOUNT
      fi
      # For Monthly APP Totals Report
      echo "----------------------------------------" >> $TOTALMONTHLYAPPCOUNT
      echo "${FDATE}      SIPR:      ${SAPPCOUNT}" >> $TOTALMONTHLYAPPCOUNT
      echo "${FDATE}      JWICS:     ${TAPPCOUNT}" >> $TOTALMONTHLYAPPCOUNT
      echo "----------------------------------------" >> $TOTALMONTHLYAPPCOUNT
      # For combined APP Totals Report
      echo "----------------------------------------" >> $TOTALCOMBINEDAPPMONTHLYCOUNT
      echo "${FDATE}      SIPR:      ${SAPPCOUNT}" >> $TOTALCOMBINEDAPPMONTHLYCOUNT
      echo "${FDATE}      JWICS:     ${TAPPCOUNT}" >> $TOTALCOMBINEDAPPMONTHLYCOUNT
      echo "----------------------------------------" >> $TOTALCOMBINEDAPPMONTHLYCOUNT
    done
    echo "####################################################" | tee -a logs/synker-$CNOW.log
    echo "#  Updated Monthly Transfer Totals to count files  #" | tee -a logs/synker-$CNOW.log
    echo "####################################################" | tee -a logs/synker-$CNOW.log
    echo
    #clear
  fi
}

function sipr_count () {
    if [ ! -f "$SIPRMONTHLYCOUNTCHECK" ]; then
      echo $CNOW > $SIPRMONTHLYCOUNTCHECK
      COUNT=1
    else
      COUNT=$(wc -l < $SIPRMONTHLYCOUNTCHECK)
    fi
}

function jwics_count () {
if [ ! -f "$JWICSMONTHLYCOUNTCHECK" ]; then
      echo $CNOW > $JWICSMONTHLYCOUNTCHECK
      COUNT=1
    else
      COUNT=$(wc -l < $JWICSMONTHLYCOUNTCHECK)
    fi
}

function sipr_app_count () {
    if [ ! -f "$SIPRMONTHLYAPPCOUNTCHECK" ]; then
      echo $CNOW > $SIPRMONTHLYAPPCOUNTCHECK
      SAPPCOUNT=1
    else
      SAPPCOUNT=$(wc -l < $SIPRMONTHLYAPPCOUNTCHECK)
    fi
}

function jwics_app_count () {
if [ ! -f "$JWICSMONTHLYAPPCOUNTCHECK" ]; then
      echo $CNOW > $JWICSMONTHLYAPPCOUNTCHECK
      TAPPCOUNT=1
    else
      TAPPCOUNT=$(wc -l < $JWICSMONTHLYAPPCOUNTCHECK)
    fi
}

function yes_or_no_delete {
    echo
    while true; do
        read -p "$* [y/n]: " yn
        echo
        case $yn in
            [Yy]*) echo -e "${YELLOW}Deleting $FILE... ${NC}";
            rm $FILE
            echo;
            echo -e "${GREEN}$FILE deleted...${NC}";
            return 0  ;;
            [Nn]*) echo -e "${YELLOW}Leaving .tar.gz file in folder...${NC}";  return  1 ;;
        esac
    done
}

function output_mm_chat_completion {
echo
echo -e "${YELLOW}######################${NC}"
echo -e "${YELLOW}#  Text for MM Chat  #${NC}"
echo -e "${YELLOW}######################${NC}"
echo
UCAPP=$(echo $APP | tr '[:lower:]' '[:upper:]')
echo -e "${GREEN}===========================================================================${NC}"
echo -e "${GREEN}${UCAPP} updates have been sent over transfer service for deployment.${NC}"
echo -e "${GREEN}\`\`\`${NC}"
echo -e "${GREEN}Filename: $FILE ${NC} " | tee -a logs/synker-$CNOW.log
echo -e "${GREEN}images:${NC}"
for i in ${APP_IMAGES[@]}
do
  IMAGE="${i%:*}"
  VERSION="${i#*:}"
  echo -e "${GREEN} -  name: $IMAGE ${NC}"
  echo -e "${GREEN}    tag: $VERSION ${NC}"
done
echo -e "${YELLOW}\`\`\`${NC}"
echo -e "${GREEN}===========================================================================${NC}"
echo

}

function pause () {
   echo -e "${YELLOW}Press enter to continue...${NC}"
   read -p "$*"
}

function local_box () {
  MESSAGE="----------------------------new script run ---------------------------------------------"
  echo $MESSAGE | tee -a logs/synker-$CNOW.log;
  clear
  echo -e "${GREEN}==============================================================================================================================================${NC}"
  echo
  echo -e "${RED}    If running from your local machine, make sure you enter AWS Temp Credentials before running this script or it will fail !${NC}"
  echo
  echo -e "${RED}    Also ensure Docker or Rancher Desktop is running on your local machine !${NC}"
  echo
  echo -e "${GREEN}==============================================================================================================================================${NC}"
  echo
}

##########################################################################################################
# End Functions
##########################################################################################################

##########################################################################################################
# Begin Main
##########################################################################################################

source ./odin-logo.sh
echo " " | tee -a logs/synker-$CNOW.log;
echo -e "${GREEN}==========================================================================================${NC}" | tee -a logs/synker-$CNOW.log;
#local_box
# BE SURE TO UPDATE ARRAY IF NEW APP ADDED
APP_ARRAY=(abms-link16ctc africom-j2 aftimes araknid clamav cole competition c2d2 c3po daf-ppbe darts decon drac force fuelai genesis idex infinityai impact jadii-ui jaimi jfac jpra-prids keycloak kraken learntowin pantheon radiance respond ripsaw saber sda sfcap space-wiki tardys3 udop ustranscom-tfa tiger-ranch virtualitics widow wingmanai)
check_new_month
clear
source ./odin-logo.sh
if [ ! -f logs/synker-$CNOW.log ]; then
  touch logs/synker-$CNOW.log
  echo "New log" | tee -a logs/synker-$CNOW.log
  date | tee -a logs/synker-$CNOW.log
else
  echo "Append log" | tee -a logs/synker-$CNOW.log
  date | tee -a logs/synker-$CNOW.log
fi
if [ -f *.gz ]; then
  rm *.gz > /dev/null
fi
cp $FOLDER/synker_template.yaml $FOLDER/synker.yaml
ODIN_TRANSFER=0
getApp
# For non-mission apps
if [ "$APP" == "other"  ]; then
  ADD_COUNT=0
  echo
  echo -n " Enter APP Name: "
  read APP
  APP_VALUE=$APP.csv
  cp csv/misc.csv csv/$APP_VALUE
  echo
  echo "App csv: $APP_VALUE"
  echo
fi
if [ "$APP2" == "nocount"  ]; then
  ADD_COUNT=0
fi

echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
echo -e "${GREEN}Please check this document to assure that there is an approved CtF for the major version request for that app !${NC}"
echo -e "${GREEN}    https://confluence.odin.dso.mil/display/DI/ODIN+Customer+CtF+Information    ${NC}"
echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
echo
pause
modifyAppCSV
modifySynkerYaml
yes_or_no_process "Build Package ? "
yes_or_no_transfer_UC2S "UC2S - Save package to AWS? "
yes_or_no_transfer_manual "Manual Transfer Option? "

if [ $FLAG == 'set' ]; then
  echo -e "${YELLOW}  Transfer flag set since copied to UC2S S3 bucket. Initiating transfer${NC}"
else
  exit
fi

# New addition for auto transfer and manual transfer option
if [ $ODIN_TRANSFER == 4 ]; then
   transfer_option_menu
fi
echo "ODIN_TRANSFER Option: $ODIN_TRANSFER" | tee -a logs/synker-$CNOW.log
if [ $ODIN_TRANSFER == 1 ]; then
   transfer_sipr
fi
if [ $ODIN_TRANSFER == 2 ]; then
   transfer_jwics
fi
if [ $ODIN_TRANSFER == 3 ]; then
   transfer_both
fi

ls -al $FILE | tee -a logs/synker-$CNOW.log
#yes_or_no_delete "Delete .tar.gz file now ? "
#rm $FILE
echo "........."
#docker images
docker images --format="{{.Repository}} {{.ID}}" | grep "^synker " | cut -d' ' -f2 | xargs docker rmi > /dev/null
#docker rmi synker:$APP-$NOW-$COUNT
echo
echo -e "${YELLOW}  Cleaned up Docker Image...${NC}"
echo
echo "........."
echo
#docker images
#echo "........."
#echo
output_mm_chat_completion
echo
echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
echo -e "${GREEN}Be sure to create merge request in IL4 Gitlab with package updates !${NC}"
echo -e "${GREEN}  https://code.il4.dso.mil/platform-one/devops/mission-bootstrap/sipr-mission-bootstrap/-/tree/master/${NC}"
echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
echo
echo -e "${GREEN}      Script completed succesfully!${NC}" | tee -a logs/synker-$CNOW.log;
echo | tee -a logs/synker-$CNOW.log;
echo

##########################################################################################################
# End Main
##########################################################################################################
