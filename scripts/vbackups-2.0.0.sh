#!/bin/bash

#-- Purpose: Manual backup script for Velero and RDS backups
#-- Tracking: Controlled in ODIN Gitlab via Git
#-- Location: ODIN Mission Bootstrap/mission-bootstrap/sipr-mission-bootstrap/scripts/
#-- Version: Controlled in ODIN Gitlab via Git
#-- Revisions: Controlled in ODIN Gitlab via Git
#-- Site/System:ODIN Platform
#-- Deficiency: NA
#-- Use: Infrastructure Deployment
#-- Users: ODIN Infrastructure Team
#-- DAC Settings: DAFCw Internal Team with Gitlab Permissions
#-- Distribution: DAFCw Team and Partners
#-- Warning: Created for the use of DAFCw and Partners
#-- Handling and Destruction Notice: No environment specific information should be distributed on releases

###################################################################################################
# Script Name: vbackups-2.0.0.sh                                                                  #
# Description: This script will create/restore velero and RDS Backup                              #
# Author     : Larry Sprouse                                                                      #
# Notes      : None                                                                               #
###################################################################################################

## Note: Need to Update DBID variables in:
## get_DSOPPROD_App, get_MISSIONPROD_App and get_MGMTPROD_App function menus to reflect your environment
## if you want to be able to do RDS backups within the script

# CHANGELOG
# Updated in V1.2.0
# Added new Mission Apps
# 1.4.0
# Added Twistlock to Mgmt-prod
# 1.5.0
# Added DSOP-TEST/APP Staging for testing purposes
# Add FULLAUTO Backup Flag
# 1.6.0
# Forgot to add ?
# 1.7.0
# Testing more auto and getting domain info
# 1.8.0
# Added more auto functionality
# Updated manual sections to only five backup or restore options - scaling added to these functions
# Updated auto CLUSTER variable option to include dsop-prod-2 since it is not standardized like other clusters
# Updated for RKE and getting cluster name from elsewhere
# 1.9.0
# Added RKE Cluster Options
# 1.10.0
# Skip scaling or fluxing
# 1.12.0
# Removing Konvoy options
# 1.13.0
# Change logging to Logging
# Add Monitoring backups to all clusters
# Test for partial failures, delete and retry
# Check for Databases before starting cluster backups
# 1.14.0 Add harbor and sdelements
# 2.0.0 Cleanup and simplification

###################################################
# Variables
###################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
NOW=$(date +"%Y-%m-%d-%H%M")
FULLAUTO="0"

###################################################
# Functions
###################################################

# This may no longer be needed since auto collecting cluster info
function chooseEnvironment () {
  while true; do
    echo
    echo -e "${GREEN}        ENVIRONMENTS"
    echo -e "${GREEN} ---------------------------"
    echo
    echo -e "${GREEN}    1) DSOP-TEST/APP-STAGING${NC}"
    echo -e "${GREEN}    2) DSOP-PROD${NC}"
    echo -e "${GREEN}    3) MISSION-PROD${NC}"
    echo -e "${GREEN}    4) MGMT-PROD${NC}"
    echo
    echo -e -n "${YELLOW} Select Environment ? ${NC}"
    read CHOICE
    echo
    case $CHOICE in
      1 ) get_DSOPTEST_App; break;;
      2 ) get_DSOPPROD_App; break;;
      3 ) get_MISSIONPROD_App; break;;
      4 ) get_MGMTPROD_App; break;;
      * ) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${RED}$CNOW Exiting since no selection was made ${NC}" | tee -a ~/tmp/vback.log; exit;;
    esac
  done
  return 0
}

get_option1 () {
    echo
    while true; do
       read -p "Full Auto Backup on all Apps in this cluster [y/n]: " yn
       echo
       echo -e "${YELLOW} !!! Make sure there are enough available AWS manual snapshots to complete rds backups for this cluster (100 Max for our account in UC2S) !! ${NC}"
       echo
       case $yn in
            [Yy]*) echo -e "${GREEN}Full Auto Backup Option Enabled...${NC}";
            echo;
            yes_or_no_are_you_sure "!!! Are you sure you want to do full auto backups on this cluster ";
            #exit;
            echo;
            FULLAUTO="1";
            CNOW=$(date +"%Y-%m-%d-%H%M");
            echo -e "${GREEN}$CNOW Fullauto backup selected for cluster${NC}" | tee -a ~/tmp/vback.log;
            getClusterName_auto;
            return 0 ; break;;
            [Nn]*) CNOW=$(date +"%Y-%m-%d-%H%M");
            echo -e "${GREEN}$CNOW Manual Backup Option Enabled...${NC}";
            FULLAUTO="0";
            CNOW=$(date +"%Y-%m-%d-%H%M");
            echo -e  "${GREEN}$CNOW Manual backups selected for cluster${NC}" | tee -a ~/tmp/vback.log;
            get_option2;
            CNOW=$(date +"%Y-%m-%d-%H%M");
            echo "$CNOW OPTION: $OPTION" | tee -a ~/tmp/vback.log;
            getClusterName;
            return  1 ; break;;
            *) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${RED}$CNOW Exiting since no selection was made ${NC}" | tee -a ~/tmp/vback.log; exit;;
        esac
    done
}

function velero_only () {
    RDSBU=1
    # Read VeleroOnly Redo for PartialFailed
    echo -e "${YELLOW}  Velero Only Backup (Skip RDS) (y/n) ?  ${NC}"
    while true; do
       read yn
       echo
       case $yn in
            [Yy]*) echo -e "${YELLOW}Velero Only Backup (Skipping RDS) ${NC}"; RDSBU=0;return 0; break;;
            [Nn]*) echo -e "${RED}RDS and Velero Backup ${NC}"; echo; break;;
            *) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${RED}$CNOW Exiting since no selection was made ${NC}" | tee -a ~/tmp/vback.log; exit;;
       esac
    done
}

get_option2 () {
    while true; do
      echo
      echo -e "${GREEN}    1) Backup${NC}"
      echo -e "${GREEN}    2) Restore  (needs further testing in DSOP-TEST before use)${NC}"
      echo
      echo -e -n "${YELLOW} Option ? ${NC}"
      read CHOICE
      echo
      case $CHOICE in
        1 ) CNOW=$(date +"%Y-%m-%d-%H%M");velero_only;OPTION=backup;echo "$CNOW $OPTION selected... " | tee -a ~/tmp/vback.log; break;;
        2 ) CNOW=$(date +"%Y-%m-%d-%H%M");OPTION=restore;echo "$CNOW $OPTION selected... " | tee -a ~/tmp/vback.log; break;;
        * ) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${RED}$CNOW Exiting since no selection was made ${NC}" | tee -a ~/tmp/vback.log; exit;;
      esac
    done
    return 0
}

function yes_or_no_are_you_sure {
    echo
    #echo -e "${RED}  !! Are you sure you want to do full auto backups on this cluster ? (y/n) !! ${NC}"
    while true; do
       read -p "$* [y/n]: " yn
       echo
       case $yn in
            [Yy]*) echo -e "${YELLOW}Full autobackups selected... ${NC}"; return 0; break;;
            [Nn]*) echo -e "${RED}Manual backups selected ${NC}"; echo; exit;;
            *) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${RED}$CNOW Exiting since no selection was made ${NC}" | tee -a ~/tmp/vback.log; exit;;
       esac
    done
}

getClusterName () {
    echo -e "${YELLOW}Getting cluster name for an RKE Cluster${NC}"
    #FOLDER=/home/maintuser/rke2-infrastructure/uc2s/dsop/dsop-test/
    #CLUSTER=$(grep -hrr "cluster_name" /home/maintuser/rke2-infrastructure/uc2s/dsop/dsop-test/cluster.hcl)
    #CLUSTER=`echo "$CLUSTER" | cut -d'"' -f 2`
    kubernetes_node=$(kubectl get nodes --no-headers -l node-role.kubernetes.io/control-plane=true | head -n1 | awk '{print $1}')
    instance_id=$(kubectl get nodes $kubernetes_node -o jsonpath='{.spec.providerID}' | sed 's:.*/::')
    server_nodepool=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value' --output text)
    cluster_id=$(echo $server_nodepool | sed 's/-server-rke2-nodepool//')
    CLUSTER=${cluster_id::-4}
    #echo $CLUSTER
  CNOW=$(date +"%Y-%m-%d-%H%M")
  echo -e "${YELLOW}$CNOW Cluster Name: $CLUSTER${NC}" | tee -a ~/tmp/vback.log
  echo
  #echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
  #echo -e "${RED}     MAKE SURE THIS IS RIGHT THE RIGHT CLUSTER: $CLUSTER${NC}"
  #echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
  #echo
  #pause
  echo
  case $CLUSTER in
      odin-dsop-test ) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${YELLOW}$CNOW Doing $CLUSTER cluster...${NC}" | tee -a ~/tmp/vback.log; get_DSOPTEST_App;;
      dsop-prod ) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${YELLOW}$CNOW Doing $CLUSTER cluster...${NC}" | tee -a ~/tmp/vback.log; get_DSOPPROD_App;;
      dsop-prod-2 ) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${YELLOW}$CNOW Doing $CLUSTER cluster...${NC}" | tee -a ~/tmp/vback.log; get_DSOPPROD_App;;
      mgmt-prod ) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${YELLOW}$CNOW Doing $CLUSTER cluster...${NC}" | tee -a ~/tmp/vback.log; get_MGMTPROD_App;;
      mission-prod ) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${YELLOW}$CNOW Doing $CLUSTER cluster...${NC}" | tee -a ~/tmp/vback.log; get_MISSIONPROD_App;;
      * ) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${RED}Cluster name is non-standard formatting. Exiting...${NC}" | tee -a ~/tmp/vback.log; exit;;
  esac
  CNOW=$(date +"%Y-%m-%d-%H%M")
  echo -e  "${GREEN}$CNOW Manual backup in $CLUSTER completed.${NC}" | tee -a ~/tmp/vback.log
  return 0
}

getClusterName_auto () {
    echo -e "${YELLOW}Getting cluster name for an RKE Cluster${NC}"
    #FOLDER=/home/maintuser/rke2-infrastructure/uc2s/dsop/dsop-test/
    #CLUSTER=$(grep -hrr "cluster_name" /home/maintuser/rke2-infrastructure/uc2s/dsop/dsop-test/cluster.hcl)
    #CLUSTER=`echo "$CLUSTER" | cut -d'"' -f 2`
    kubernetes_node=$(kubectl get nodes --no-headers -l node-role.kubernetes.io/control-plane=true | head -n1 | awk '{print $1}')
    instance_id=$(kubectl get nodes $kubernetes_node -o jsonpath='{.spec.providerID}' | sed 's:.*/::')
    server_nodepool=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[].Instances[].Tags[?Key==`Name`].Value' --output text)
    cluster_id=$(echo $server_nodepool | sed 's/-server-rke2-nodepool//')
    CLUSTER=${cluster_id::-4}
    #echo $CLUSTER
  CNOW=$(date +"%Y-%m-%d-%H%M")
  echo -e "${YELLOW}$CNOW Cluster Name: $CLUSTER${NC}" | tee -a ~/tmp/vback.log
  echo
  #echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
  #echo -e "${RED}     MAKE SURE THIS IS RIGHT THE RIGHT CLUSTER: $CLUSTER${NC}"
  #echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
  #echo
  #pause
  echo
  case $CLUSTER in
      odin-dsop-test ) echo -e "${YELLOW}Doing $CLUSTER cluster...${NC}"; get_DSOPTEST_App_auto;;
      dsop-prod ) echo -e "${YELLOW}Doing $CLUSTER cluster...${NC}"; get_DSOPPROD_App_auto;;
      dsop-prod-2 ) echo -e "${YELLOW}Doing $CLUSTER cluster...${NC}"; get_DSOPPROD_App_auto;;
      mgmt-prod ) echo -e "${YELLOW}Doing $CLUSTER cluster...${NC}"; get_MGMTPROD_App_auto;;
      mission-prod ) echo -e "${YELLOW}Doing $CLUSTER cluster...${NC}"; get_MISSIONPROD_App_auto;;
      * ) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${RED}$CNOW Exiting since no selection was made ${NC}" | tee -a ~/tmp/vback.log; exit;;
  esac
  CNOW=$(date +"%Y-%m-%d-%H%M")
  echo -e  "${GREEN}$CNOW Auto backup in $CLUSTER completed.${NC}" | tee -a ~/tmp/vback.log
  return 0
}

get_DSOPTEST_App_auto () {
   # keycloak
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=keycloak; NS=keycloak; DBID=dsop-test-keycloak-rke-db;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; rds_onlyBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # argocd
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=argocd; NS=argocd;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; argocdBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;
   # anchore
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=anchore; NS=anchore; DBID=dsop-test-anchore-db; echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; anchoreBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # confluence
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=confluence; NS=confluence; DBID=dsop-test-confluence-01;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # fortify
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=fortify; NS=fortify; DBID=fortify-dsop-test;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # gitlab
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=gitlab; NS=gitlab; DBID=odin-dsop-test-gitlab-db;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; gitlabBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # harbor
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=harbor; NS=harbor; DBID=odin-dsop-test-harbor-db;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # jira
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=jira; NS=jira; DBID=dsop-test-jira;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # logging
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=logging; NS=logging;echo -e "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # mattermost
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=mattermost; NS=mattermost; DBID=mattermost-test-db;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; mattermostBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # monitoring
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=monitoring; NS=monitoring;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # nexus
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=nexus; NS=nexus-repository-manager;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # sdelements
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=sdelements; NS=sdelements; DBID=sdelements-odin-dsop-test-database;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # sonarqube
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=sonarqube; NS=sonarqube; DBID=odin-dsop-test-sonarqube-db;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; rds_onlyBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # twistlock
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=twistlock; NS=twistlock;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; twistlockBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   return 0
}

get_DSOPPROD_App_auto () {
   # anchore
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=anchore; NS=anchore; DBID=dsop-anchore-db1;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; anchoreBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;
   # confluence
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=confluence; NS=confluence; DBID=dsop-prod-confluence-01;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;
   # fortify
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=fortify; NS=fortify; DBID=fortify-old;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;
   # gitlab
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=gitlab; NS=gitlab; DBID=odin-gold-dsop-prod-gitlab-db1;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; gitlabBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;
   # harbor
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=harbor; NS=harbor; DBID=dsop-prod-harbor;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # jira
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=jira; NS=jira; DBID=dsop-prod-jira;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;
   # logging
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=logging; NS=logging;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; kibanaBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;
   # mattermost
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=mattermost; NS=mattermost; DBID=mattermost;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; mattermostBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;\
   # monitoring
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=monitoring; NS=monitoring;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;
   # nexus
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=nexus; NS=nexus-repository-manager;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; nexusBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;
   # sdelements
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=sdelements; NS=sdelements; DBID=sdelements-dsop-prod-database;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # sonarqube
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=sonarqube; NS=sonarqube; DBID=odin-dsop-prod-sonarqube-db;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; rds_onlyBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;
   # twistlock
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=twistlock; NS=twistlock;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; twistlockBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;
   return 0
}

get_MGMTPROD_App_auto () {
   # keycloak
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=keycloak; NS=keycloak; DBID=mgmt-prod-keycloak;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; rds_onlyBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # logging
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=logging; NS=logging;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;
   # monitoring
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=monitoring; NS=monitoring;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # twistlock
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=twistlock; NS=twistlock;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; twistlockBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
  return 0
}

get_MISSIONPROD_App_auto () {
   # padawan
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=padawan; NS=padawan;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; mission_app_backup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;
   # argocd
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=argocd; NS=argocd;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; argocdBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;
   # logging
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=logging; NS=logging;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M");
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log;
   # monitoring
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=monitoring; NS=monitoring;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   # twistlock
   CNOW=$(date +"%Y-%m-%d-%H%M")
   APP=twistlock; NS=twistlock;echo -e  "${CYAN}$CNOW Auto backup started for $APP${NC}" | tee -a ~/tmp/vback.log; twistlockBackup;
   CNOW=$(date +"%Y-%m-%d-%H%M")
   echo -e  "${GREEN}$CNOW Auto backup completed for $APP${NC}" | tee -a ~/tmp/vback.log
   echo
  return 0
}

get_DSOPTEST_App () {
  while true; do
    echo
    echo -e "${GREEN}        APPS"
    echo -e "${GREEN} ---------------------------"
    echo
    echo -e "${GREEN}    1)   Anchore${NC}"
    echo -e "${GREEN}    2)   Confluence${NC}"
    echo -e "${GREEN}    3)   Fortify${NC}"
    echo -e "${GREEN}    4)   Gitlab${NC}"
    echo -e "${GREEN}    5)   Jira${NC}"
    echo -e "${GREEN}    6)   Keycloak${NC}"
    echo -e "${GREEN}    7)   Logging${NC}"
    echo -e "${GREEN}    8)   Mattermost${NC}"
    echo -e "${GREEN}    9)   Monitoring${NC}"
    echo -e "${GREEN}    10)  Nexus${NC}"
    echo -e "${GREEN}    11)  Sonarqube${NC}"
    echo -e "${GREEN}    12)  Twistlock${NC}"
    echo -e "${GREEN}    13)  ArgoCD${NC}"
    echo -e "${GREEN}    14)  Harbor${NC}"
    echo -e "${GREEN}    15)  SDElements${NC}"
    echo
    echo -e -n "${YELLOW} Select App to backup or restore ? ${NC}"
    read CHOICE
    echo
    case $CHOICE in
      1 ) APP=anchore; NS=anchore; DBID=dsop-test-anchore-db;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; anchoreBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      2 ) APP=confluence; NS=confluence; DBID=dsop-test-confluence-01;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      3 ) APP=fortify; NS=fortify; DBID=fortify-test;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      4 ) APP=gitlab; NS=gitlab; DBID=odin-dsop-test-gitlabdb;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; gitlabBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      5 ) APP=jira; NS=jira; DBID=dsop-test-jira;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      6 ) APP=keycloak; NS=keycloak; DBID=dsop-test-keycloak-rke-db;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; rds_onlyBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      7 ) APP=logging; NS=logging;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      8 ) APP=mattermost; NS=mattermost; DBID=mattermost-test-db;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; mattermostBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      9 ) APP=monitoring; NS=monitoring;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      10 ) APP=nexus; NS=nexus-repository-manager;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      11 ) APP=sonarqube; NS=sonarqube; DBID=odin-dsop-test-sonarqube-db;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; rds_onlyBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      12 ) APP=twistlock; NS=twistlock;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; twistlockBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      13 ) APP=argocd; NS=argocd;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; argocdBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      14 ) APP=harbor; NS=harbor; DBID=odin-dsop-test-harbor-db;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      15 ) APP=sdelements; NS=sdelements; DBID=sdelements-odin-dsop-test-database;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      * ) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${RED}$CNOW Exiting since no selection was made ${NC}" | tee -a ~/tmp/vback.log; exit;;
    esac
  done
  return 0
}

get_DSOPPROD_App () {
  while true; do
    echo
    echo -e "${GREEN}        APPS"
    echo -e "${GREEN} ---------------------------"
    echo
    echo -e "${GREEN}    1)  Anchore${NC}"
    echo -e "${GREEN}    2)  Confluence${NC}"
    echo -e "${GREEN}    3)  Fortify${NC}"
    echo -e "${GREEN}    4)  Gitlab${NC}"
    echo -e "${GREEN}    5)  Jira${NC}"
    echo -e "${GREEN}    6)  Logging${NC}"
    echo -e "${GREEN}    7)  Mattermost${NC}"
    echo -e "${GREEN}    8)  Monitoring${NC}"
    echo -e "${GREEN}    9)  Nexus${NC}"
    echo -e "${GREEN}    10) Sonarqube${NC}"
    echo -e "${GREEN}    11) Twistlock${NC}"
    echo
    echo -e -n "${YELLOW} Select App to backup or restore ? ${NC}"
    read CHOICE
    echo
    case $CHOICE in
      1 ) APP=anchore; NS=anchore; DBID=dsop-anchore-db1;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; anchoreBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      2 ) APP=confluence; NS=confluence; DBID=dsop-prod-confluence-01;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      3 ) APP=fortify; NS=fortify; DBID=fortify-old;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      4 ) APP=gitlab; NS=gitlab; DBID=odin-gold-dsop-prod-gitlab-db1;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; gitlabBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      5 ) APP=jira; NS=jira; DBID=dsop-prod-jira;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      6 ) APP=logging; NS=logging;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      7 ) APP=mattermost; NS=mattermost; DBID=mattermost;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; mattermostBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      8 ) APP=monitoring; NS=monitoring;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      9 ) APP=nexus; NS=nexus-repository-manager;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      10 ) APP=sonarqube; NS=sonarqube; DBID=odin-dsop-prod-sonarqube-db;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; rds_onlyBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      11 ) APP=twistlock; NS=twistlock;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; twistlockBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      12 ) APP=harbor; NS=harbor; DBID=dsop-prod-harbor;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      13 ) APP=sdelements; NS=sdelements; DBID=sdelements-dsop-prod-database;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_rds_Backup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      * ) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${RED}$CNOW Exiting since no selection was made ${NC}" | tee -a ~/tmp/vback.log; exit;;
    esac
  done
  return 0
}

get_MISSIONPROD_App () {
  while true; do
    echo
    echo -e "${GREEN}        MISSIONS"
    echo -e "${GREEN} ---------------------------"
    echo
    echo -e "${GREEN}    1) ARAKNID${NC}"
    echo -e "${GREEN}    2) BATTLEDRILL${NC}"
    echo -e "${GREEN}    3) C3PO${NC}"
    echo -e "${GREEN}    4) FSCA BASALT${NC}"
    echo -e "${GREEN}    5) GENESIS${NC}"
    echo -e "${GREEN}    6) JAIMI${NC}"
    echo -e "${YELLOW}    7) LEXI - Inactive${NC}"
    echo -e "${GREEN}    8) SPACECOCKPIT${NC}"
    echo -e "${GREEN}    9) WIDOW${NC}"
    echo -e "${GREEN}    10) TIGER RANCH${NC}"
    echo -e "${GREEN}    11) RDPL${NC}"
    echo -e "${GREEN}    12) WINGMAN AI${NC}"
    echo -e "${GREEN}    13) FUEL AI${NC}"
    echo -e "${GREEN}    14) STITCHES${NC}"
    echo -e "${GREEN}    15) COLE${NC}"
    echo -e "${GREEN}    16) COMPETITION${NC}"
    echo -e "${GREEN}    17) DARTS${NC}"
    echo -e "${GREEN}    18) GSW-ODIN${NC}"
    echo -e "${GREEN}    19) LEARN-TO-WIN${NC}"
    echo -e "${GREEN}    20) VIRTUALITICS${NC}"
    echo -e "${GREEN}    21) PADAWAN${NC}"
    echo
    echo -e "${GREEN}    95) ArgoCD${NC}"
    echo -e "${GREEN}    96) Logging${NC}"
    echo -e "${GREEN}    97) Monitoring${NC}"
    echo -e "${GREEN}    98) Twistlock${NC}"
    echo
    echo -e -n "${YELLOW} Select Mission to backup or restore ? ${NC}"
    read CHOICE
    echo
    case $CHOICE in
      1 ) APP=araknid; NS=araknid; mission_app_backup; break;;
      2 ) APP=battledrill; NS=battledrill; mission_app_backup; break;;
      3 ) APP=c3po; NS=c3po; mission_app_backup; break;;
      4 ) APP=basalt; NS=jaic-fsca; DBID=jaic-db; mission_app_backup_rds_only; break;;
      5 ) APP=genesis; NS=genesis; mission_app_backup; break;;
      6 ) APP=jaimi; NS=jaimi; mission_app_backup; break;;
      7 ) break; APP=lexi; NS=lexi; mission_app_backup; break;;
      8 ) break; APP=saber; NS=saber; DBID=saber-db; mission_app_backup_with_rds; break;;
      9 ) APP=widow; NS=widow; DBID=odin-mission-prod-apps-widow; mission_app_backup_rds_only; break;;
      10 ) APP=tigerranch; NS=tiger-ranch; DBID=odin-mission-prod-apps-tiger-ranch; mission_app_backup_with_rds; break;;
      11 ) APP=rdpl; NS=rdpl; mission_app_backup; break;;
      12 ) APP=wingmanai; NS=wingmanai; DBID=odin-mission-prod-apps-wingmanai; mission_app_backup_rds_only; break;;
      13 ) APP=fuelai; NS=fuelai; DBID=odin-mission-prod-apps-fuelai; mission_app_backup_rds_only; break;;
      14 ) APP=stitches; NS=abms-link16ctc; mission_app_backup; break;;
      15 ) APP=cole; NS=cole; mission_app_backup; break;;
      16 ) APP=competition; NS=competition; mission_app_backup; break;;
      17 ) APP=darts; NS=darts; mission_app_backup; break;;
      18 ) APP=gsw-odin; NS=gsw-odin; mission_app_backup; break;;
      19 ) APP=learn-to-win; NS=learn-to-win; mission_app_backup; break;;
      20 ) APP=virtualitics; NS=virtualitics; mission_app_backup; break;;
      21 ) APP=padawan; NS=padawan; mission_app_backup; break;;
      95 ) APP=argocd; NS=argocd;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; argocdBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M")
          echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      96 ) APP=logging; NS=logging;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M")
          echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      97 ) APP=monitoring; NS=monitoring; velero_onlyBackup;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      98 ) APP=twistlock; NS=twistlock;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; twistlockBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M")
          echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      * ) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${RED}$CNOW Exiting since no selection was made ${NC}" | tee -a ~/tmp/vback.log; exit;;
    esac
  done
  return 0
}

get_MGMTPROD_App () {
  while true; do
    echo
    echo -e "${GREEN}        APPS"
    echo -e "${GREEN} ---------------------------"
    echo
    echo -e "${GREEN}    1) KEYCLOAK${NC}"
    echo -e "${GREEN}    2) Logging${NC}"
    echo -e "${GREEN}    3) Monitoring${NC}"
    echo -e "${GREEN}    4) Twistlock${NC}"
    echo
    echo -e -n "${YELLOW} Select App to backup or restore ? ${NC}"
    read CHOICE
    echo
    case $CHOICE in
      1 ) APP=keycloak; NS=keycloak; DBID=mgmt-prod-keycloak;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      2 ) APP=logging; NS=logging;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log; velero_onlyBackup;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      3 ) APP=monitoring; NS=monitoring; velero_onlyBackup;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      4 ) APP=twistlock; NS=twistlock; twistlockBackup;CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${CYAN}$CNOW Manual backup started for $APP${NC}" | tee -a ~/tmp/vback.log;
          CNOW=$(date +"%Y-%m-%d-%H%M");echo -e  "${GREEN}$CNOW Manual backup completed for $APP${NC}" | tee -a ~/tmp/vback.log; break;;
      * ) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${RED}$CNOW Exiting since no selection was made ${NC}" | tee -a ~/tmp/vback.log; exit;;
    esac
  done
  return 0
}

## CORE FUNCTIONS ##

argocd_login () {
  echo -e "${YELLOW}killing any open port forwarding sesions for argocd${NC}"
  rid=$(ps -aux | grep kubectl | grep argocd | grep port-forward | awk '{print $2}')
  kill -9 $rid
  echo -e "${BLUE}Argocd login...${NC}"
  kubectl -n argocd port-forward svc/argocd-argocd-server 8080:80 > /dev/null &
  BGPID=$!
  echo "Process id: $BGPID"
  sleep 3
  argocd login localhost:8080 --grpc-web
}

argocd_logout () {
  echo "Argocd logout..."
  argocd logout localhost:8080
  kill $BGPID
}

argocd_prod_syncoff () {
  argocd app set sipr-mission-prod --sync-policy none
  echo -e "${GREEN}Completed setting sipr-mission-prod --sync-policy none...${NC}"
  sleep 10
}

argocd_prod_syncauto () {
  echo
  argocd app set sipr-mission-prod --sync-policy auto
  echo -e "${GREEN}Completed setting sipr-mission-prod --sync-policy auto...${NC}"
  sleep 10
  argocd app set sipr-mission-prod --auto-prune
  sleep 10
  echo -e "${GREEN}Completed setting sipr-mission-prod --auto-prune...${NC}"
  sleep 10
  echo -e "${GREEN}Doing prune force on $APP...${NC}"
  argocd app sync sipr-mission-prod --prune --force
  sleep 30
}

argocd_app_syncoff () {
  argocd app set sipr-mission-prod-$NS-$NS --sync-policy none
  echo -e "${GREEN}Completed setting sipr-mission-prod-$NS-$NS --sync-policy none...${NC}"
  sleep 10
  argocd app set sipr-mission-prod-integrations-$NS --sync-policy none
  echo -e "${GREEN}Completed setting sipr-mission-prod-integrations-$NS --sync-policy none...${NC}"
  sleep 10
}

argocd_app_syncauto () {
  argocd app set sipr-mission-prod-$NS-$NS --sync-policy auto
  echo -e "${GREEN}Completed setting sipr-mission-prod-$NS-$NS --sync-policy auto...${NC}"
  sleep 10
  argocd app set sipr-mission-prod-$NS-$NS --auto-prune
  echo -e "${GREEN}Completed setting sipr-mission-prod-$NS-$NS --auto-prune...${NC}"
  sleep 10
  argocd app set sipr-mission-prod-integrations-$NS --sync-policy auto
  echo -e "${GREEN}Completed setting sipr-mission-prod-integrations-$NS --sync-policy auto...${NC}"
  sleep 10
  argocd app set sipr-mission-prod-integrations-$NS --auto-prune
  echo -e "${GREEN}Completed setting sipr-mission-prod-integrations-$NS --auto-prune...${NC}"
  sleep 10
  echo -e "${GREEN}Doing prune force on $APP...${NC}"
  argocd app sync sipr-mission-prod-$NS-$NS --prune --force
  sleep 10
  argocd app sync sipr-mission-prod-integrations-$NS --prune --force
  sleep 30
  argocd app list
}

checkUser () {
  getUser=$(whoami)
  if [[ "${getUser}" != "maintuser"  ]]; then
    echo -e "${RED}This script needs to be executed as maintuser, exiting script!${NC}"
    exit 1
  fi
}

flux_all () {
  flux reconcile source git this -n bigbang
  flux reconcile kustomization -n bigbang bigbang-umbrella
  flux reconcile kustomization -n bigbang thirdparty-umbrella
  flux get kustomizations -A
  flux suspend hr -n bigbang bigbang
  flux resume hr -n bigbang bigbang
  flux reconcile hr -n bigbang bigbang
}

flux_suspend () {
  flux suspend hr -n bigbang $NS
}

flux_resume () {
  flux resume hr -n bigbang $NS
  fluxall
}

pause () {
   echo -e "${YELLOW}Press enter to continue...${NC}"
   read -p "$*"
}

rds_backup () {
  NOW=$(date +"%Y-%m-%d-%H%M")
  echo
  echo -e "${YELLOW}Backing up $APP RDS...${NC}"
  aws rds create-db-snapshot --db-instance-identifier $DBID  --db-snapshot-identifier $DBID-backup-$NOW
  sleep 10
  DB_STATUS="busy"
  while :
  do
    sleep 30
    rds_status
    if [ $DB_STATUS == "busy" ]; then
       echo -e "${YELLOW}        ...waiting 30 seconds...${NC}"
       sleep 30
    else
       echo "Database is available"
       echo
       #echo -e "${YELLOW}Manually verify completion of rds backup before continuing${NC}"
       #pause
       echo -e "${CYAN}RDS backup created: $DBID-backup-$NOW ${NC}" | tee -a ~/tmp/vback.log
       echo -e "${GREEN}RDS Backup complete...${NC}"
       break
    fi
  done
}

rds_restore () {
  NOW=$(date +"%Y-%m-%d-%H%M")
  echo
  echo -e "${YELLOW}Restoring $APP RDS...${NC}"
  aws rds describe-db-instances | grep DBInstanceIdentifier
  echo -e "${YELLOW}RDS restore is a manual process... Do it Now!${NC}" | tee -a ~/tmp/vback.log
  pause
  echo -e "${GREEN}RDS restore complete...${NC}"
}

rds_status () {
  #aws rds describe-db-instances --db-instance-identifier $DBID
  RDS_CHECK=$(aws rds describe-db-instances --db-instance-identifier $DBID | grep DBInstanceStatus)
  if [[ $RDS_CHECK =~ "available" ]]; then
    echo -e "${GREEN}     RDS is online and available.${NC}"
    DB_STATUS="good"
  fi
  if [[ $RDS_CHECK =~ "backing-up" ]]; then
    echo -e "${YELLOW}     RDS is being backed up.${NC}"
    DB_STATUS="busy"
  fi
  if [[ $RDS_CHECK =~ "maintenance" ]]; then
    echo -e "${YELLOW}     RDS is in maintenance mode.${NC}"
    DB_STATUS="busy"
  fi
}

scale_down_deploy_and_stateful () {
  NOW=$(date +"%Y-%m-%d-%H%M")
  kubectl delete jobs -n $NS --all
  kubectl scale deployment --all --replicas=0 -n $NS &> /dev/null
  kubectl scale statefulset --all --replicas=0 -n $NS &> /dev/null
  # Used for twistlock. scale daemonsets does not seem to work
  #kubectl -n twistlock patch daemonset twistlock-defender-ds -p '{"spec": {"template": {"spec": {"nodeSelector": {"non-existing": "true"}}}}}'
  #kubectl scale daemonsets --all --replicas=0 -n $NS &> /dev/null
  LC=0
  #echo -en "Verifying namespace pods are scaled down..."
  while :
  do
    PE=$(kubectl get pods -n $NS)
    if [ -n "$PE" ]; then
       echo -ne "Verifying namespace pods are scaled down... $LC sec\033[0K\r"
       sleep 1
       LC=$((LC+1))
    else
       echo -e "${GREEN}Scaling complete...${NC}"
       echo
       break
    fi
  done
}

scale_up_deploy () {
  echo -e "${YELLOW}Scaling up deployment...${NC}"
  echo "Namespace: $NS"
  kubectl scale deployment --all --replicas=1 -n $NS
  sleep 30
  echo -e "${GREEN}Scaling complete...${NC}"
}

scale_up_stateful () {
  echo -e "${YELLOW}Scaling up statefulsets...${NC}"
  kubectl scale statefulset --all --replicas=1 -n $NS
  sleep 30
  echo -e "${GREEN}Scaling complete...${NC}"
}

velero_backup () {
  kubectl scale deployment --all --replicas=5 -n velero
  NOW=$(date +"%Y-%m-%d-%H%M")
  echo -e "${YELLOW}Starting velero backup...${NC}"
  velero backup create $APP-$NOW-pvonly --include-resources pvc,pv --include-namespaces $NS --ttl 7200h0m0s --wait
  echo -e "${GREEN}Completed velero backup...${NC}"
  echo
  sleep 60
  echo -e "${YELLOW}Describing velero backup...${NC}"
  echo
  velero backup describe $APP-$NOW-pvonly
  echo -e "${CYAN}Velero backup created: $APP-$NOW-pvonly${NC}" | tee -a ~/tmp/vback.log
  #velero backup logs $APP-$NOW-pvonly
  echo
  sleep 10
  echo "Show current $NS velero backups..."
  velero get backups | grep $APP
  kubectl scale deployment --all --replicas=1 -n velero
}

velero_backup_restore () {
  echo
  echo -e "${YELLOW}Need to delete PV/PVC's for $APP...${NC}"
  kubectl get pv -A | grep $NS
  kubectl get pvc -A | grep $NS
  echo -e "${YELLOW}Getting pv/pvc info for $APP...${NC}"
  PV_TO_DELETE=$(kubectl get pvc -A|grep $NS|awk '{print $4 " "}')
  kubectl delete pvc -n $NS --all
  kubectl delete pv $PV_TO_DELETE
  echo -e "${YELLOW}Deleting pvc's for $APP...${NC}"
  sleep 10
  #read -p "Enter pvc name to delete ? " pvcdelete
  #read -p "Are you sure you want to delete pvc $pvcdelete (y/n) ? " yn
  #if [ "$yn" = y ]; then
  #  kubectl delete pvc -n $NS $pvcdelete
  #  kubectl get pv | grep $APP
  #  kubectl get pvc -n $NS
  #elif [ "$yn" = n ]; then
  #  break
  #else
  #  echo "Not a valid answer."
  #  exit
  #fi
  echo -e "${YELLOW}Restoring velero backup for $APP...${NC}"
  velero get backups | grep $APP
  read -p "Enter backup name to restore ? " backuptorestore
  velero restore create --from-backup $backuptorestore --wait
  echo -e "${CYAN}Velero restore completed for: $backuptorestore ${NC}}" | tee -a ~/tmp/vback.log
  echo -e "${YELLOW}Completed restore, sleeping for 30 seconds and then check for pvc claim issue... $APP...${NC}"
  sleep 5
  velero get restores | grep $APP
  sleep 5
}

function velero_only () {
    RDSBU=1
    # Read Velero Only - Redo Option for PartialFailed
    while true; do
       echo -e -n "${YELLOW}  Velero Only Backup (Skip RDS) ? (y/n) !! ${NC}"
       read yn
       echo
       case $yn in
            [Yy]*) echo -e "${YELLOW}Velero Only Backup, skipping RDS backup.${NC}"; RDSBU=0;return 0; break;;
            [Nn]*) echo -e "${RED}Velero Backup including RDS if needed.${NC}"; echo; break;;
            *) CNOW=$(date +"%Y-%m-%d-%H%M");echo -e "${RED}$CNOW Exiting since no selection was made ${NC}" | tee -a ~/tmp/vback.log; exit;;
       esac
    done
}

## BIG BANG APP FUNCTIONS ##

anchoreBackup () {
  if [[ "$FULLAUTO" == "1" ]]; then
    velero_backup
    rds_backup
  else
    kubectl get all -n $NS
    if [[ "${OPTION}" == "backup"  ]]; then
      echo -e "${YELLOW}Backing up $UCAPP${NC}"
      velero_backup
      if [[ "$RDSBU" == "1" ]]; then
        rds_backup
      fi
    fi
    if [[ "${OPTION}" == "restore"  ]]; then
      echo -e "${YELLOW}Restoring $UCAPP${NC}"
      flux_suspend
      kubectl delete jobs -n $NS --all
      scale_down_deploy_and_stateful
      velero_backup_restore
      echo -e "${YELLOW}Restore your RDS Database and continue after completed.${NC}"
      echo -e "${YELLOW}Change your db hostname endpoint in patch-bigbang.yaml${NC}"
      pause 'Press [Enter] key to continue...'
      scale_up_deploy
      scale_up_stateful
      flux_resume
    fi
  fi
  return 0
}

argocdBackup () {
  if [[ "$FULLAUTO" == "1" ]]; then
    velero_backup
  else
    kubectl get all -n $NS
    if [[ "${OPTION}" == "backup"  ]]; then
      echo -e "${YELLOW}Backing up $UCAPP${NC}"
      velero_backup
    fi
    if [[ "${OPTION}" == "restore"  ]]; then
      echo -e "${YELLOW}Restoring $UCAPP${NC}"
      velero_backup_restore
      flux_all
    fi
  fi
  return 0
}

#confluenceBackup () {
#  if [[ "$FULLAUTO" == "1" ]]; then
#    velero_backup
#    rds_backup
#  else
#    kubectl get all -n $NS
#    if [[ "${OPTION}" == "backup"  ]]; then
#      echo -e "${YELLOW}Backing up $UCAPP${NC}"
#      velero_backup
#      if [[ "$RDSBU" == "1" ]]; then
#        rds_backup
#      fi
#    fi
#    if [[ "${OPTION}" == "restore"  ]]; then
#      echo -e "${YELLOW}Restoring $UCAPP${NC}"
#      flux suspend hr -n bigbang $NS
#      scale_down_deploy_and_stateful
#      velero_backup_restore
#      echo -e "${YELLOW}Restore your RDS Database and continue after completed.${NC}"
#      echo -e "${YELLOW}Change your db hostname endpoint in patch-bigbang.yaml${NC}"
#      pause 'Press [Enter] key to continue...'
#      scale_up_deploy
#      scale_up_stateful
#      flux_resume
#    fi
#  fi
#  return 0
#}

#fortifyBackup () {
#  if [[ "$FULLAUTO" == "1" ]]; then
#    velero_backup
#    rds_backup
#  else
#    kubectl get all -n $NS
#    if [[ "${OPTION}" == "backup"  ]]; then
#      echo -e "${YELLOW}Backing up $UCAPP${NC}"
#      velero_backup
#      if [[ "$RDSBU" == "1" ]]; then
#        rds_backup
#      fi
#    fi
#    if [[ "${OPTION}" == "restore"  ]]; then
#      flux_suspend
#      scale_down_deploy_and_stateful
#      echo -e "${YELLOW}Restoring $UCAPP${NC}"
#      velero_backup_restore
#      echo -e "${YELLOW}Restore your RDS Database and continue after completed.${NC}"
#      echo -e "${YELLOW}Change your db hostname endpoint in patch-bigbang.yaml${NC}"
#      pause 'Press [Enter] key to continue...'
#      scale_up_deploy
#      scale_up_stateful
#      flux_resume
#    fi
#  fi
#  return 0
#}

gitlabBackup () {
  echo "Backing up Gitlab..."
  if [[ "$FULLAUTO" == "1" ]]; then
    echo -e "${YELLOW}Backing up $UCAPP${NC}"
    sudo cp /home/git/sipr-mission-bootstrap/bigbang/core/envs/prod/patch-bigbang.yaml /home/maintuser/tmp/patch-bigbang-$NOW.yaml
    A=$(cat ~/tmp/patch-bigbang-$NOW.yaml | grep "railsSecret" -A1)
    B=$(echo $A | awk '{print $3}')
    kubectl get secrets -n gitlab $B -o yaml > ~/tmp/$B-backup-$NOW.yaml
    yq d -i ~/tmp/$B-backup-$NOW.yaml 'metadata.annotations' --
    yq d -i ~/tmp/$B-backup-$NOW.yaml 'metadata.creationTimestamp' --
    yq d -i ~/tmp/$B-backup-$NOW.yaml 'metadata.labels' --
    yq d -i ~/tmp/$B-backup-$NOW.yaml 'metadata.managedFields' --
    yq d -i ~/tmp/$B-backup-$NOW.yaml 'metadata.resourceVersion' --
    yq d -i ~/tmp/$B-backup-$NOW.yaml 'metadata.uid' --
    aws s3 cp ~/tmp/$B-backup-$NOW.yaml s3://velero-backups/$CLUSTER/
    cp ~/tmp/$B-backup-$NOW.yaml ~/tmp/$B-backup.yaml
    aws s3 cp ~/tmp/$B-backup.yaml s3://velero-backups/$CLUSTER/
    sudo chown git:git ~/tmp/$B-backup-$NOW.yaml ~/tmp/$B-backup.yaml ~/tmp/patch-bigbang-$NOW.yaml
    sudo mv ~/tmp/$B-backup-$NOW.yaml ~/tmp/$B-backup.yaml ~/tmp/patch-bigbang-$NOW.yaml /home/git/backups/
    velero_backup
    rds_backup
  else
    kubectl get all -n $NS
    if [[ "${OPTION}" == "backup"  ]]; then
      echo -e "${YELLOW}Backing up $UCAPP${NC}"
      sudo cp /home/git/sipr-mission-bootstrap/bigbang/core/envs/prod/patch-bigbang.yaml /home/maintuser/tmp/patch-bigbang-$NOW.yaml
      A=$(cat ~/tmp/patch-bigbang-$NOW.yaml | grep "railsSecret" -A1)
      B=$(echo $A | awk '{print $3}')
      kubectl get secrets -n gitlab $B -o yaml > ~/tmp/$B-backup-$NOW.yaml
      yq d -i ~/tmp/$B-backup-$NOW.yaml 'metadata.annotations' --
      yq d -i ~/tmp/$B-backup-$NOW.yaml 'metadata.creationTimestamp' --
      yq d -i ~/tmp/$B-backup-$NOW.yaml 'metadata.labels' --
      yq d -i ~/tmp/$B-backup-$NOW.yaml 'metadata.managedFields' --
      yq d -i ~/tmp/$B-backup-$NOW.yaml 'metadata.resourceVersion' --
      yq d -i ~/tmp/$B-backup-$NOW.yaml 'metadata.uid' --
      aws s3 cp ~/tmp/$B-backup-$NOW.yaml s3://velero-backups/$CLUSTER/
      cp ~/tmp/$B-backup-$NOW.yaml ~/tmp/$B-backup.yaml
      aws s3 cp ~/tmp/$B-backup.yaml s3://velero-backups/$CLUSTER/
      sudo chown git:git ~/tmp/$B-backup-$NOW.yaml ~/tmp/$B-backup.yaml ~/tmp/patch-bigbang-$NOW.yaml
      sudo mv ~/tmp/$B-backup-$NOW.yaml ~/tmp/$B-backup.yaml ~/tmp/patch-bigbang-$NOW.yaml /home/git/backups/
      velero_backup
      if [[ "$RDSBU" == "1" ]]; then
        rds_backup
      fi
    fi
    if [[ "${OPTION}" == "restore"  ]]; then
      echo -e "${YELLOW}Restoring $UCAPP${NC}"
      flux_suspend
      flux suspend hr -n bigbang $NS-runner
      kubectl delete jobs -n $NS --all
      scale_down_deploy_and_stateful
      velero_backup_restore
      #rds_restore
      echo -e "${YELLOW}Restore your RDS Database and continue after completed.${NC}"
      echo -e "${YELLOW}Change your db hostname endpoint in patch-bigbang.yaml${NC}"
      pause 'Press [Enter] key to continue...'
      kubectl delete secret -n gitlab gitlab-rails-secret
      aws s3 cp s3://velero-backups/$CLUSTER/gitlab_rails_secret_backup.yaml .
      kubectl apply -f gitlab_rails_secret_backup.yaml
      rm gitlab_rails_secret_backup.yaml
      scale_up_deploy
      scale_up_stateful
      flux resume hr -n bigbang $NS
      flux resume hr -n bigbang $NS-runner
    fi
  fi
  return 0
}

rds_onlyBackup () {
  echo "Get current $NS velero backups..."
  velero get backups | grep $NS
  if [[ "$FULLAUTO" == "1" ]]; then
    rds_backup
  else
    kubectl get all -n $NS
    if [[ "${OPTION}" == "backup"  ]]; then
      echo -e "${YELLOW}Backing up $UCAPP${NC}"
      rds_backup
    fi
    if [[ "${OPTION}" == "restore"  ]]; then
      echo -e "${YELLOW}Restoring $UCAPP${NC}"
      flux_suspend
      scale_down_deploy_and_stateful
      echo -e "${YELLOW}Restore your RDS Database and continue after completed.${NC}"
      echo -e "${YELLOW}Change your db hostname endpoint in patch-bigbang.yaml${NC}"
      pause 'Press [Enter] key to continue...'
      scale_up_stateful
      flux resume hr -n bigbang $NS
    fi
  fi
  return 0
}

velero_onlyBackup () {
  if [[ "$FULLAUTO" == "1" ]]; then
    velero_backup
  else
    kubectl get all -n $NS
    if [[ "${OPTION}" == "backup"  ]]; then
      echo -e "${YELLOW}Backing up $UCAPP${NC}"
      velero_backup
    fi
    if [[ "${OPTION}" == "restore"  ]]; then
      echo -e "${YELLOW}Restoring $UCAPP${NC}"
      flux_suspend
      scale_down_deploy_and_stateful
      velero_backup_restore
      scale_up_deploy
      flux_resume
    fi
  fi
  return 0
}

velero_rds_Backup () {
  if [[ "$FULLAUTO" == "1" ]]; then
    velero_backup
    rds_backup
  else
    kubectl get all -n $NS
    if [[ "${OPTION}" == "backup"  ]]; then
      echo -e "${YELLOW}Backing up $UCAPP${NC}"
      velero_backup
      if [[ "$RDSBU" == "1" ]]; then
        rds_backup
      fi
    fi
    if [[ "${OPTION}" == "restore"  ]]; then
      flux_suspend
      kubectl delete jobs -n $NS --all
      scale_down_deploy_and_stateful
      echo -e "${YELLOW}Restoring $UCAPP${NC}"
      velero_backup_restore
      echo -e "${YELLOW}Restore your RDS Database and continue after completed.${NC}"
      echo -e "${YELLOW}Change your db hostname endpoint in patch-bigbang.yaml${NC}"
      pause 'Press [Enter] key to continue...'
      scale_up_deploy
      scale_up_stateful
      flux_resume
    fi
  fi
  return 0
}

#keycloakBackup () {
#  echo "Get current $NS velero backups..."
#  velero get backups | grep $NS
#  if [[ "$FULLAUTO" == "1" ]]; then
#    rds_backup
#  else
#    kubectl get all -n $NS
#    if [[ "${OPTION}" == "backup"  ]]; then
#      echo -e "${YELLOW}Backing up $UCAPP${NC}"
#      rds_backup
#    fi
#    if [[ "${OPTION}" == "restore"  ]]; then
#      echo -e "${YELLOW}Restoring $UCAPP${NC}"
#      flux_suspend
#      scale_down_deploy_and_stateful
#      echo -e "${YELLOW}Restore your RDS Database and continue after completed.${NC}"
#      echo -e "${YELLOW}Change your db hostname endpoint in patch-bigbang.yaml${NC}"
#      pause 'Press [Enter] key to continue...'
#      scale_up_stateful
#      flux_suspend
#      flux resume hr -n bigbang $NS
#    fi
#  fi
#  return 0
#}

#sonarqubeBackup () {
#  echo "Get current $NS velero backups..."
#  velero get backups | grep $NS
#  if [[ "$FULLAUTO" == "1" ]]; then
#    rds_backup
#  else
#    kubectl get all -n $NS
#    if [[ "${OPTION}" == "backup"  ]]; then
#      echo -e "${YELLOW}Backing up $UCAPP${NC}"
#      rds_backup
#    fi
#    if [[ "${OPTION}" == "restore"  ]]; then
#      echo -e "${YELLOW}Restoring $UCAPP${NC}"
#      flux_suspend
#      scale_down_deploy_and_stateful
#      echo -e "${YELLOW}Restore your RDS Database and continue after completed.${NC}"
#      echo -e "${YELLOW}Change your db hostname endpoint in patch-bigbang.yaml${NC}"
#      pause 'Press [Enter] key to continue...'
#      scale_up_stateful
#      flux resume hr -n bigbang $NS
#    fi
#  fi
#  return 0
#}

#loggingBackup () {
#  if [[ "$FULLAUTO" == "1" ]]; then
#    velero_backup
#  else
#    kubectl get all -n $NS
#    if [[ "${OPTION}" == "backup"  ]]; then
#      echo -e "${YELLOW}Backing up $UCAPP${NC}"
#      velero_backup
#    fi
#    if [[ "${OPTION}" == "restore"  ]]; then
#      echo -e "${YELLOW}Restoring $UCAPP${NC}"
#      velero_backup_restore
#      flux_all
#    fi
#  fi
#  return 0
#}
#
#monitoringBackup () {
#  if [[ "$FULLAUTO" == "1" ]]; then
#    velero_backup
#  else
#    kubectl get all -n $NS
#    if [[ "${OPTION}" == "backup"  ]]; then
#      echo -e "${YELLOW}Backing up $UCAPP${NC}"
#      velero_backup
#    fi
#    if [[ "${OPTION}" == "restore"  ]]; then
#      echo -e "${YELLOW}Restoring $UCAPP${NC}"
#      velero_backup_restore
#      flux_all
#    fi
#  fi
#  return 0
#}
#
#nexusBackup () {
#  if [[ "$FULLAUTO" == "1" ]]; then
#    velero_backup
#  else
#    kubectl get all -n $NS
#    if [[ "${OPTION}" == "backup"  ]]; then
#      echo -e "${YELLOW}Backing up $UCAPP${NC}"
#      velero_backup
#    fi
#    if [[ "${OPTION}" == "restore"  ]]; then
#      echo -e "${YELLOW}Restoring $UCAPP${NC}"
#      flux_suspend
#      scale_down_deploy_and_stateful
#      velero_backup_restore
#      scale_up_deploy
#      flux_resume
#    fi
#  fi
#  return 0
#}

mattermostBackup () {
  if [[ "$FULLAUTO" == "1" ]]; then
    rds_backup
  else
    kubectl get all -n $NS
    echo "...in backup OPTION: $OPTION"
    if [[ "${OPTION}" == "backup"  ]]; then
      echo -e "${YELLOW}Backing up $UCAPP${NC}"
      rds_backup
    fi
    if [[ "${OPTION}" == "restore"  ]]; then
      echo -e "${YELLOW}Restoring $UCAPP${NC}"
      echo -e "${YELLOW}Backing up $UCAPP${NC}"
      flux suspend hr -n bigbang mattermost-operator
      flux suspend hr -n bigbang mattermost
      kubectl delete jobs -n $NS --all
      kubectl scale deployment --all --replicas=0 -n mattermost-operator &> /dev/null
      echo -e "${YELLOW}Scaling down mattermost-operator deployment...{NC}"
      sleep 5
      kubectl scale deployment --all --replicas=0 -n mattermost &> /dev/null
      echo -e "${YELLOW}Scaling down mattermost deployment...{NC}"
      # Nothing to backup - no pv's or pvc's
      #velero_backup_restore
      echo -e "${YELLOW}Restore your RDS Database and continue after completed.${NC}"
      echo -e "${YELLOW}Change your db hostname endpoint in patch-bigbang.yaml${NC}"
      pause 'Press [Enter] key to continue...'
      flux resume hr -n bigbang mattermost-operator
      flux resume hr -n bigbang mattermost
      fluxall
    fi
  fi
  return 1
}

twistlockBackup () {
  if [[ "$FULLAUTO" == "1" ]]; then
    velero_backup
    echo
  else
    kubectl get all -n $NS
    if [[ "${OPTION}" == "backup"  ]]; then
      echo -e "${YELLOW}Backing up $UCAPP${NC}"
      velero_backup
    fi
    if [[ "${OPTION}" == "restore"  ]]; then
      echo -e "${YELLOW}Restoring $UCAPP${NC}"
      flux_suspend
      kubectl -n twistlock patch daemonset twistlock-defender-ds -p '{"spec": {"template": {"spec": {"nodeSelector": {"non-existing": "true"}}}}}'
      scale_down_deploy_and_stateful
      velero_backup_restore
      scale_up_deploy
      flux resume hr -n bigbang $NS
      ##cd /home/git/gitlab/twistlock/
      ##kustomize build .  | kubectl create -f-
      kubectl -n twistlock patch daemonset twistlock-defender-ds --type json -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector/non-existing"}]'
    fi
  fi
  return 0
}


## MISSION APP FUNCTIONS ##

mission_app_backup () {
  if [[ "$FULLAUTO" == "1" ]]; then
    #argocd_login
    #argocd_prod_syncoff
    #argocd_app_syncoff
    #scale_down_deploy_and_stateful
    #argocd_logout
    velero_backup
    #argocd_login
    #scale_up_deploy
    #argocd_app_syncauto
    #echo -e "${YELLOW}Commented out argocd_prod_sync - need to run manually if not doing anymore backups.${NC}"
    #argocd_prod_syncauto
    #sleep 10
    #argocd app list
    #argocd_logout
  else
    kubectl get all -n $NS
    if [[ "${OPTION}" == "backup"  ]]; then
      echo -e "${YELLOW}Backing up $UCAPP${NC}"
      #argocd_login
      #argocd_prod_syncoff
      #argocd_app_syncoff
      #scale_down_deploy_and_stateful
      #argocd_logout
      velero_backup
      #argocd_login
      #scale_up_deploy
      #argocd_app_syncauto
      #echo -e "${YELLOW}Commented out argocd_prod_sync - need to run manually if not doing anymore backups.${NC}"
      #argocd_prod_syncauto
      #sleep 10
      #argocd app list
      #argocd_logout
    fi
    if [[ "${OPTION}" == "restore"  ]]; then
      echo -e "${YELLOW}Restoring $UCAPP${NC}"
      echo "NS: $NS - Not sure if this works yet..."
      pause
      argocd_login
      argocd_prod_syncoff
      argocd_app_syncoff
      scale_down_deploy_and_stateful
      argocd_logout
      velero_backup_restore
      argocd_login
      scale_up_deploy
      argocd_app_syncauto
      #echo -e "${YELLOW}Commented out argocd_prod_sync - need to run manually if not doing anymore backups.${NC}"
      argocd_prod_syncauto
      sleep 10
      argocd app list
      argocd_logout
    fi
  fi
  return 0
}

mission_app_backup_with_rds () {
  if [[ "$FULLAUTO" == "1" ]]; then
    #argocd_login
    #argocd_prod_syncoff
    #argocd_app_syncoff
    #scale_down_deploy_and_stateful
    #argocd_logout
    velero_backup
    rds_backup
    #argocd_login
    #scale_up_deploy
    #argocd_app_syncauto
    #echo -e "${YELLOW}Commented out argocd_prod_sync - need to run manually if not doing anymore backups.${NC}"
    #argocd_prod_syncauto
    #sleep 10
    #argocd app list
    #argocd_logout
  else
    kubectl get all -n $NS
    if [[ "${OPTION}" == "backup"  ]]; then
      echo -e "${YELLOW}Backing up $UCAPP${NC}"
      #argocd_login
      #argocd_prod_syncoff
      #argocd_app_syncoff
      #scale_down_deploy_and_stateful
      #argocd_logout
      velero_backup
      rds_backup
      #argocd_login
      #scale_up_deploy
      #argocd_app_syncauto
      #echo -e "${YELLOW}Commented out argocd_prod_sync - need to run manually if not doing anymore backups.${NC}"
      #argocd_prod_syncauto
      #sleep 10
      #argocd app list
      #argocd_logout
    fi
    if [[ "${OPTION}" == "restore"  ]]; then
      echo -e "${YELLOW}Restoring $UCAPP${NC}"
      echo "NS: $NS - Not sure if this works yet..."
      pause
      argocd_login
      argocd_prod_syncoff
      argocd_app_syncoff
      scale_down_deploy_and_stateful
      argocd_logout
      velero_backup_restore
      echo -e "${YELLOW}Restore your RDS Database and continue after completed.${NC}"
      echo -e "${YELLOW}Change your db hostname endpoint in patch-bigbang.yaml${NC}"
      pause 'Press [Enter] key to continue...'
      argocd_login
      scale_up_deploy
      argocd_app_syncauto
      #echo -e "${YELLOW}Commented out argocd_prod_sync - need to run manually if not doing anymore backups.${NC}"
      argocd_prod_syncauto
      sleep 10
      argocd app list
      argocd_logout
    fi
  fi
  return 0
}

mission_app_backup_rds_only () {
  if [[ "$FULLAUTO" == "1" ]]; then
    #argocd_login
    #argocd_prod_syncoff
    #argocd_app_syncoff
    #scale_down_deploy_and_stateful
    #argocd_logout
    rds_backup
    #argocd_login
    #scale_up_deploy
    #argocd_app_syncauto
    #echo -e "${YELLOW}Commented out argocd_prod_sync - need to run manually if not doing anymore backups.${NC}"
    #argocd_prod_syncauto
    #sleep 10
    #argocd app list
    #argocd_logout
  else
    kubectl get all -n $NS
    if [[ "${OPTION}" == "backup"  ]]; then
      echo -e "${YELLOW}Backing up $UCAPP${NC}"
      #argocd_login
      #argocd_prod_syncoff
      #argocd_app_syncoff
      #scale_down_deploy_and_stateful
      #argocd_logout
      rds_backup
      #argocd_login
      #scale_up_deploy
      #argocd_app_syncauto
      #echo -e "${YELLOW}Commented out argocd_prod_sync - need to run manually if not doing anymore backups.${NC}"
      #argocd_prod_syncauto
      sleep 10
      #argocd app list
      #argocd_logout
    fi
    if [[ "${OPTION}" == "restore"  ]]; then
      echo -e "${YELLOW}Restoring $UCAPP${NC}"
      echo "NS: $NS - Not sure if this works yet..."
      pause
      argocd_login
      argocd_prod_syncoff
      argocd_app_syncoff
      scale_down_deploy_and_stateful
      argocd_logout
      echo -e "${YELLOW}Restore your RDS Database and continue after completed.${NC}"
      echo -e "${YELLOW}Change your db hostname endpoint in patch-bigbang.yaml${NC}"
      pause 'Press [Enter] key to continue...'
      argocd_login
      scale_up_deploy
      argocd_app_syncauto
      #echo -e "${YELLOW}Commented out argocd_prod_sync - need to run manually if not doing anymore backups.${NC}"
      argocd_prod_syncauto
      sleep 10
      argocd app list
      argocd_logout
    fi
  fi
  return 0
}

###################################################
# Main Script
###################################################
source /bootstrap/scripts/odin-logo.sh
# Temporary Flg to use for Partially Failed backups to skip RDS backup
RDSBU=1
cd ~
#clear
LOG=~/tmp/vback.log
if [ ! -f "$LOG" ]; then
  cd ~
  mkdir tmp
  touch ~/tmp/vback.log
  echo " " | tee -a ~/tmp/vback.log
  CNOW=$(date +"%Y-%m-%d-%H%M")
  echo "$CNOW Log created" | tee -a ~/tmp/vback.log
fi
echo "..............................................." | tee -a ~/tmp/vback.log
CNOW=$(date +"%Y-%m-%d-%H%M")
echo "$CNOW Backup script started" | tee -a ~/tmp/vback.log
checkUser
#kubectl scale deployment --all --replicas=0 -n velero
#sleep 30
#kubectl scale deployment --all --replicas=5 -n velero
get_option1
#getClusterName

# Commented out for full auto backup
# This is used to stay in the script loop until you decided to quit
#FLAG=1
#while [ $FLAG -eq 1 ]
#do
#  #chooseEnvironment
#done

#argocd app list
#argocd app get "app name" --hard-refresh
#argocd app sync "app name" --force --prune

#kubectl scale deployment --all --replicas=1 -n velero

echo
velero get backups | grep $(date +"%Y-%m-%d")
echo
aws rds describe-db-snapshots --query 'DBSnapshots[].DBSnapshotIdentifier' | grep $(date +"%Y-%m-%d") | grep $CLUSTER > ~/tmp/rds-snapshots.txt
grep -v "rds:" ~/tmp/ ~/tmp/rds-snapshots.txt | awk '{ print $2 }'
echo

CNOW=$(date +"%Y-%m-%d-%H%M")
echo "$CNOW Backup script completed" | tee -a ~/tmp/vback.log
echo " " | tee -a ~/tmp/vback.log
echo
echo -e "${GREEN} Script completed succesfully!${NC}"
echo


