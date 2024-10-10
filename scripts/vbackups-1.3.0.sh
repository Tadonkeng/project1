#!/bin/bash

###################################################################################################
# Script Name: vbackup.sh                                                                         #
# Description: This script will create velero backups                                             #
# Author     : Larry Sprouse                                                                      #
# Version    : 1.3.0                                                                              #
# Notes      : None                                                                               #
###################################################################################################

## Note: Need to Update DBID variables in:
## get_DSOPPROD_App, get_MISSIONPROD_App and get_MGMTPROD_App function menus to reflect your environment
## if you want to be able to do RDS backups within the script

# Updated in V1.2.0
# Added new Mission Apps

# Variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
NOW=$(date +"%Y-%m-%d-%H%M")

# Functions

chooseEnvironment () {
#get_MISSIONPROD_App
#get_MGMTPROD_App
  while true; do
    echo
    echo -e "${GREEN}        ENVIRONMENTS"
    echo -e "${GREEN} ---------------------------"
    echo
    echo -e "${GREEN}    1) DSOP-PROD${NC}"
    echo -e "${GREEN}    2) MISSION-PROD${NC}"
    echo -e "${GREEN}    3) MGMT-PROD${NC}"
    echo
    echo -e -n "${YELLOW} Select Environment ? ${NC}"
    read CHOICE
    echo
    case $CHOICE in
      1 ) get_DSOPPROD_App; break;;
      2 ) get_MISSIONPROD_App; break;;
      3 ) get_MGMTPROD_App; break;;
      * ) echo -e "${RED}Exiting since no selection was made ${NC}"; exit;;
    esac
  done
  UCAPP=${APP^^}
  MESSAGE="$UCAPP selected for backup..."
  echo $MESSAGE >> ~/tmp/vback.log
  return 0
}

get_DSOPPROD_App () {
  while true; do
    echo
    echo -e "${GREEN}        APPS"
    echo -e "${GREEN} ---------------------------"
    echo
    echo -e "${GREEN}    1) Anchore${NC}"
    echo -e "${GREEN}    2) Confluence${NC}"
    echo -e "${GREEN}    3) Fortify${NC}"
    echo -e "${GREEN}    4) Gitlab${NC}"
    echo -e "${GREEN}    5) Jira${NC}"
    echo -e "${GREEN}    6) Nexus${NC}"
    echo -e "${GREEN}    7) Twistlock${NC}"
    echo -e "${GREEN}    8) Kibana${NC}"
    echo -e "${GREEN}    9) Mattermost${NC}"
    echo
    echo -e -n "${YELLOW} Select App to backup ? ${NC}"
    read CHOICE
    echo
    case $CHOICE in
      1 ) APP=anchore; NS=anchore; DBID=dsop-anchore-db1; anchoreBackup; break;;
      2 ) APP=confluence; NS=confluence; DBID=odin-dsop-prod-confluence-db confluenceBackup; break;;
      3 ) APP=fortify; NS=fortify; DBID=fortify; fortifyBackup; break;;
      4 ) APP=gitlab; NS=gitlab; DBID=p1k-odin-dsop-prod-gitlabdb; gitlabBackup; break;;
      5 ) APP=jira; NS=jira; DBID=odin-dsop-prod-jira-db; jiraBackup; break;;
      6 ) APP=nexus; NS=nexus-repository-manager; nexusBackup; break;;
      7 ) APP=twistlock; NS=twistlock; twistlockBackup; break;;
      8 ) APP=kibana; NS=logging; kibanaBackup; break;;
      9 ) APP=mattermost; NS=mattermost; mattermostBackup; break;;
      * ) echo -e "${RED}Exiting since no selection was made ${NC}"; exit;;
    esac
  done
  UCAPP=${APP^^}
  MESSAGE="$UCAPP selected for backup..."
  echo $MESSAGE >> ~/tmp/vback.log
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
    echo -e "${YELLOW}    6) JAIMI - needs installed${NC}"
    echo -e "${YELLOW}    7) LEXI - Inactive${NC}"
    echo -e "${YELLOW}    8) SPACECOCKPITi - disabled${NC}"
    echo -e "${GREEN}    9) WIDOW${NC}"
    echo -e "${GREEN}    10) TIGER RANCH${NC}"
    echo -e "${GREEN}    11) RDPL${NC}"
    echo -e "${GREEN}    12) WINGMAN AI${NC}"
    echo -e "${GREEN}    13) FUEL AI${NC}"
    echo -e "${GREEN}    14) STITCHES${NC}"

    echo
    echo -e -n "${YELLOW} Select Mission to backup ? ${NC}"
    read CHOICE
    echo
    case $CHOICE in
      1 ) APP=araknid; NS=araknid; mission_app_backup; break;;
      2 ) APP=battledrill; NS=battledrill; mission_app_backup; break;;
      3 ) APP=c3po; NS=c3po; mission_app_backup; break;;
      4 ) APP=basalt; NS=jaic-fsca; DBID=jaic-db; mission_app_backup_rds_only; break;;
      5 ) APP=genesis; NS=genesis; mission_app_backup; break;;
      6 ) break; APP=jaimi; NS=jaimi; mission_app_backup; break;;
      7 ) break; APP=lexi; NS=lexi; mission_app_backup; break;;
      8 ) break; APP=saber; NS=saber; DBID=saber-db; mission_app_backup_with_rds; break;;
      9 ) APP=widow; NS=widow; DBID=odin-mission-prod-apps-widow; mission_app_backup_rds_only; break;;
      10 ) APP=tigerranch; NS=tiger-ranch; DBID=odin-mission-prod-apps-tiger-ranch; mission_app_backup_with_rds; break;;
      11 ) APP=rdpl; NS=rdpl; mission_app_backup; break;;
      12 ) APP=wingmanai; NS=wingmanai; DBID=odin-mission-prod-apps-wingmanai; mission_app_backup_rds_only; break;;
      13 ) APP=fuelai; NS=fuelai; DBID=odin-mission-prod-apps-fuelai; mission_app_backup_rds_only; break;;
      14 ) APP=stitches; NS=abms-link16ctc; mission_app_backup; break;;
      * ) echo -e "${RED}Exiting since no selection was made ${NC}"; exit;;
    esac
  done
  UCAPP=${APP^^}
  MESSAGE="$UCAPP selected for backup..."
  echo $MESSAGE >> ~/tmp/vback.log
  return 0
}

get_MGMTPROD_App () {
  while true; do
    echo
    echo -e "${GREEN}        APPS"
    echo -e "${GREEN} ---------------------------"
    echo
    echo -e "${GREEN}    1) KEYCLOAK${NC}"
    echo
    echo -e -n "${YELLOW} Select App to backup ? ${NC}"
    read CHOICE
    echo
    case $CHOICE in
      1 ) APP=keycloak; NS=keycloak; DBID=keycloak-mgmt-prod-bb121; keycloakBackup; break;;
      * ) echo -e "${RED}Exiting since no selection was made ${NC}"; exit;;
    esac
  done
  UCAPP=${APP^^}
  MESSAGE="$UCAPP selected for backup..."
  echo $MESSAGE >> ~/tmp/vback.log
  return 0
}

get_option () {
    while true; do
    echo
    echo -e "${GREEN}    1) Scale Down Namespace${NC}"
    echo -e "${GREEN}    2) Backup${NC}"
    echo -e "${GREEN}    3) Restore${NC}"
    echo -e "${GREEN}    4) Scale Up Namespace${NC}"
    echo
    echo -e -n "${YELLOW} Option ? ${NC}"
    read CHOICE
    echo
    case $CHOICE in
      1 ) OPTION=scaledown; break;;
      2 ) OPTION=backup; break;;
      3 ) OPTION=restore; break;;
      4 ) OPTION=scaleup; break;;
      * ) echo -e "${RED}Exiting since no selection was made ${NC}"; exit;;
    esac
  done
  MESSAGE="$OPTION selected..."
  echo $MESSAGE >> ~/tmp/vback.log
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
    rds_status
    sleep 10
    #DB_STATUS=$(aws rds describe-db-instances --db-instance-identifier $DBID | grep DBInstanceStatus)
    if [ $DB_STATUS == "busy" ]; then
       echo -e "${YELLOW}        ...waiting 10 seconds...${NC}"
       sleep 10
    else
       echo "Database is available"
       echo
       echo -e "${YELLOW}Manually verify completion of rds backup before continuing${NC}"
       pause
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
  echo -e "${YELLOW}Currently a manual process... Do it Now!${NC}"
  pause
  echo -e "${GREEN}RDS Backup complete...${NC}"
}

rds_status () {
  #aws rds describe-db-instances --db-instance-identifier $DBID
  RDS_CHECK=$(aws rds describe-db-instances --db-instance-identifier $DBID | grep DBInstanceStatus)
  if [[ $RDS_CHECK =~ "available" ]]; then
    echo -e "${GREEN}RDS is online and available.${NC}"
    DB_STATUS="good"
  fi
  if [[ $RDS_CHECK =~ "backing-up" ]]; then
    echo -e "${YELLOW}RDS is being backed up.${NC}"
    DB_STATUS="busy"
  fi
  if [[ $RDS_CHECK =~ "maintenance" ]]; then
    echo -e "${YELLOW}RDS is in maintenance mode.${NC}"
    DB_STATUS="busy"
  fi
}

scale_down_deploy_and_stateful () {
  NOW=$(date +"%Y-%m-%d-%H%M")
  kubectl scale deployment --all --replicas=0 -n $NS &> /dev/null
  kubectl scale statefulset --all --replicas=0 -n $NS &> /dev/null
  kubectl scale daemonsets --all --replicas=0 -n $NS &> /dev/null
  LC=0
  while :
  do
    PE=$(kubectl get pods -n $NS)
    if [ -n "$PE" ]; then
       echo "verifying namespace pods are scaled down..."
       sleep 10
       # Maybe not needed... had some extra pods that were evicted and would not go away without these steps
       #if [ "${NS}" == "tiger-ranch" ] && [ "${LC}" == "5" ]; then
       #  echo "here..."
       #  #kubectl delete pods -n tiger-ranch --all
       #fi
       #LC=$((LC+1))
       #echo "LC= $LC"
    else
       echo "Deployment terminated"
       echo -e "${GREEN}Scaling complete...${NC}"
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
  NOW=$(date +"%Y-%m-%d-%H%M")
  echo "Get current $NS velero backups..."
  velero get backups | grep $NS
  echo -e "${YELLOW}Starting velero backup...${NC}"
  velero backup create $APP-$NOW-pvonly --include-resources pvc,pv --include-namespaces $NS --ttl 7200h0m0s --wait
  echo -e "${GREEN}Completed velero backup...${NC}"
  velero backup describe $APP-$NOW-pvonly
  #velero backup logs $APP-$NOW-pvonly
  sleep 10
  echo "Get current $NS velero backups..."
  velero get backups | grep $NS
}

velero_backup_restore () {
  echo
  echo -e "${YELLOW}Need to delete PVC/PVC's for $APP...${NC}"
  kubectl get pvc -n $NS
  kubectl delete pvc -n $NS --all
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
  velero restore create --from-backup $backuptorestore
  sleep 10
  velero get restores
}

## BIG BANG APP FUNCTIONS ##

anchoreBackup () {
  get_option
  kubectl get all -n $NS
  if [[ "${OPTION}" == "scaledown"  ]]; then
    flux suspend hr -n bigbang $NS
    kubectl delete jobs -n $NS --all
    scale_down_deploy_and_stateful
  fi
  if [[ "${OPTION}" == "backup"  ]]; then
    echo -e "${YELLOW}Backing up $UCAPP${NC}"
    velero_backup
    rds_backup
  fi
  if [[ "${OPTION}" == "restore"  ]]; then
    echo -e "${YELLOW}Restoring $UCAPP${NC}"
    velero_backup_restore
  fi
  if [[ "${OPTION}" == "scaleup"  ]]; then
    scale_up_deploy
    scale_up_stateful
    flux resume hr -n bigbang $NS
  fi
  return 0
}

confluenceBackup () {
  get_option
  kubectl get all -n $NS
  if [[ "${OPTION}" == "scaledown"  ]]; then
    flux suspend hr -n bigbang $NS
    scale_down_deploy_and_stateful
  fi
  if [[ "${OPTION}" == "backup"  ]]; then
    echo -e "${YELLOW}Backing up $UCAPP${NC}"
    velero_backup
    rds_backup
  fi
  if [[ "${OPTION}" == "restore"  ]]; then
    echo -e "${YELLOW}Restoring $UCAPP${NC}"
    velero_backup_restore
  fi
  if [[ "${OPTION}" == "scaleup"  ]]; then
    scale_up_deploy
    flux resume hr -n bigbang $NS
  fi
  return 0
}

fortifyBackup () {
  get_option
  kubectl get all -n $NS
  if [[ "${OPTION}" == "scaledown"  ]]; then
    flux suspend hr -n bigbang $NS
    scale_down_deploy_and_stateful
  fi
  if [[ "${OPTION}" == "backup"  ]]; then
    echo -e "${YELLOW}Backing up $UCAPP${NC}"
    velero_backup
    rds_backup
  fi
  if [[ "${OPTION}" == "restore"  ]]; then
    echo -e "${YELLOW}Restoring $UCAPP${NC}"
    velero_backup_restore
  fi
  if [[ "${OPTION}" == "scaleup"  ]]; then
    scale_up_deploy
    flux resume hr -n bigbang $NS
  fi
  return 0
}

gitlabBackup () {
  echo "Backing up Gitlab..."
  get_option
  kubectl get all -n $NS
  if [[ "${OPTION}" == "scaledown"  ]]; then
    flux suspend hr -n bigbang $NS
    flux suspend hr -n bigbang $NS-runner
    kubectl delete jobs -n $NS --all
    scale_down_deploy_and_stateful
  fi
  if [[ "${OPTION}" == "backup"  ]]; then
    echo -e "${YELLOW}Backing up $UCAPP${NC}"
    kubectl get secrets -n gitlab gitlab-rails-secret -o yaml > gitlab_rails_secret_backup-$NOW.yaml
    aws s3 cp gitlab_rails_secret_backup-$NOW.yaml s3://velero-backups/dsop-prod/
    cp gitlab_rails_secret_backup-$NOW.yaml gitlab_rails_secret_backup.yaml
    aws s3 cp gitlab_rails_secret_backup.yaml s3://velero-backups/dsop-prod/
    rm gitlab_rails_secret_backup-$NOW.yaml
    velero_backup
    rds_backup
    echo -e "${YELLOW}Wait until DB snapshot complete and back Available before Scaling Back up.${NC}"
    pause 'Press [Enter] key to continue...'
  fi
  if [[ "${OPTION}" == "restore"  ]]; then
    echo -e "${YELLOW}Restoring $UCAPP${NC}"
    echo "NS: $NS"
    echo -e "${YELLOW}Restore your RDS Database and continue after completed.${NC}"
    echo -e "${YELLOW}Change your db hostname endpoint in patch-bigbang.yaml${NC}"
    pause 'Press [Enter] key to continue...'
    #rds_restore
    velero_backup_restore
    #echo -e "${BLUE}Find gitlab_rails secret and kubectl apply it...${NC}"
    kubectl delete secret -n gitlab gitlab-rails-secret
    aws s3 cp s3://velero-backups/dsop-prod/gitlab_rails_secret_backup.yaml .
    kubectl apply -f gitlab_rails_secret_backup.yaml
    rm gitlab_rails_secret_backup.yaml
    # should not need this anymore
    #/bootstrap/scrips/gitlab-object-storage-secret.sh
  fi
  if [[ "${OPTION}" == "scaleup"  ]]; then
    scale_up_deploy
    scale_up_stateful
    flux resume hr -n bigbang $NS
    flux resume hr -n bigbang $NS-runner
  fi
  return 0
}

jiraBackup () {
  get_option
  kubectl get all -n $NS
  if [[ "${OPTION}" == "scaledown"  ]]; then
    scale_down_deploy_and_stateful
  fi
  if [[ "${OPTION}" == "backup"  ]]; then
    echo -e "${YELLOW}Backing up $UCAPP${NC}"
    velero_backup
    rds_backup
  fi
  if [[ "${OPTION}" == "restore"  ]]; then
    echo -e "${YELLOW}Restoring $UCAPP${NC}"
    velero_backup_restore
  fi
  if [[ "${OPTION}" == "scaleup"  ]]; then
    scale_up_deploy
  fi
  return 0
}

keycloakBackup () {
  echo "Get current $NS velero backups..."
  velero get backups | grep $NS
  echo -e "${RED}This one not working yet - SIPR-PB-BOOTSTRAP and not a Deployment."
  echo -e "${RED}Also, Velero not installed in this environment yet."
  exit
  get_option
  kubectl get all -n $NS
  if [[ "${OPTION}" == "scaledown"  ]]; then
    scale_down_deploy_and_stateful
  fi
  if [[ "${OPTION}" == "backup"  ]]; then
    echo -e "${YELLOW}Backing up $UCAPP${NC}"
    velero_backup
    rds_backup
  fi
  if [[ "${OPTION}" == "restore"  ]]; then
    echo -e "${YELLOW}Restoring $UCAPP${NC}"
    velero_backup_restore
  fi
  if [[ "${OPTION}" == "scaleup"  ]]; then
    scale_up_stateful
    flux resume hr -n bigbang $NS
  fi
  return 0
}

kibanaBackup () {
  get_option
  kubectl get all -n $NS
  if [[ "${OPTION}" == "scaledown"  ]]; then
    echo -e "${YELLOW}Scaling not required for Kibana $UCAPP${NC}"
  fi
  if [[ "${OPTION}" == "backup"  ]]; then
    echo -e "${YELLOW}Backing up $UCAPP${NC}"
    velero_backup
  fi
  if [[ "${OPTION}" == "restore"  ]]; then
    echo -e "${YELLOW}Restoring $UCAPP${NC}"
    echo "NS: $NS"
    echo "y"|flux delete hr -n bigbang fluentd
    echo "y"|flux delete hr -n bigbang fluent-bit
    echo "y"|flux delete hr -n bigbang jaeger
    echo "y"|flux delete hr -n bigbang ek
    sleep 60
    kubectl get pvc -n logging
    velero_backup_restore
    flux_all
  fi
  if [[ "${OPTION}" == "scaleup"  ]]; then
    echo -e "${YELLOW}Scaling not required for Kibana $UCAPP${NC}"
    sleep 10
  fi
  return 0
}

nexusBackup () {
  get_option
  kubectl get all -n $NS
  if [[ "${OPTION}" == "scaledown"  ]]; then
    flux_suspend
    scale_down_deploy_and_stateful
  fi
  if [[ "${OPTION}" == "backup"  ]]; then
    echo -e "${YELLOW}Backing up $UCAPP${NC}"
    velero_backup
  fi
  if [[ "${OPTION}" == "restore"  ]]; then
    echo -e "${YELLOW}Restoring $UCAPP${NC}"
    echo "NS: $NS"
    velero_backup_restore
  fi
  if [[ "${OPTION}" == "scaleup"  ]]; then
    scale_up_deploy
    flux resume hr -n bigbang $NS
  fi
  return 0
}


mattermostBackup () {
  get_option
  kubectl get all -n $NS
  if [[ "${OPTION}" == "scaledown"  ]]; then
    flux_suspend
    scale_down_deploy_and_stateful
  fi
  if [[ "${OPTION}" == "backup"  ]]; then
    echo -e "${YELLOW}Backing up $UCAPP${NC}"
    velero_backup
  fi
  if [[ "${OPTION}" == "restore"  ]]; then
    echo -e "${YELLOW}Restoring $UCAPP${NC}"
    echo "NS: $NS"
    velero_backup_restore
  fi
  if [[ "${OPTION}" == "scaleup"  ]]; then
    scale_up_deploy
    flux resume hr -n bigbang $NS
  fi
  return 0
}

twistlockBackup () {
  get_option
  kubectl get all -n $NS
  if [[ "${OPTION}" == "scaledown"  ]]; then
    scale_down_deploy_and_stateful
  fi
  if [[ "${OPTION}" == "backup"  ]]; then
    echo -e "${YELLOW}Backing up $UCAPP${NC}"
    velero_backup
  fi
  if [[ "${OPTION}" == "restore"  ]]; then
    echo -e "${YELLOW}Restoring $UCAPP${NC}"
    velero_backup_restore
  fi
  if [[ "${OPTION}" == "scaleup"  ]]; then
    scale_up_deploy
    flux resume hr -n bigbang $NS
  fi
  return 0
}


## MISSION APP FUNCTIONS ##
mission_app_backup () {
  get_option
  if [[ "${OPTION}" == "scaledown"  ]]; then
    argocd_login
    argocd_prod_syncoff
    argocd_app_syncoff
    scale_down_deploy_and_stateful
    argocd_logout
  fi
  if [[ "${OPTION}" == "backup"  ]]; then
    echo -e "${YELLOW}Backing up $UCAPP${NC}"
    velero_backup
  fi
  if [[ "${OPTION}" == "restore"  ]]; then
    echo -e "${YELLOW}Restoring $UCAPP${NC}"
    velero_backup_restore
  fi
  if [[ "${OPTION}" == "scaleup"  ]]; then
    argocd_login
    scale_up_deploy
    argocd_app_syncauto
    #echo -e "${YELLOW}Commented out argocd_prod_sync - need to run manually if not doing anymore backups.${NC}"
    argocd_prod_syncauto
    sleep 10
    argocd app list
    argocd_logout
  fi
  return 0
}

mission_app_backup_with_rds () {
  get_option
  if [[ "${OPTION}" == "scaledown"  ]]; then
    argocd_login
    argocd_prod_syncoff
    argocd_app_syncoff
    scale_down_deploy_and_stateful
    argocd_logout
  fi
  if [[ "${OPTION}" == "backup"  ]]; then
    echo -e "${YELLOW}Backing up $UCAPP${NC}"
    velero_backup
    rds_backup
  fi
  if [[ "${OPTION}" == "restore"  ]]; then
    echo -e "${YELLOW}Restoring $UCAPP${NC}"
    velero_backup_restore
    rds_restore
  fi
  if [[ "${OPTION}" == "scaleup"  ]]; then
    argocd_login
    scale_up_deploy
    argocd_app_syncauto
    #echo -e "${YELLOW}Commented out argocd_prod_sync - need to run manually if not doing anymore backups.${NC}"
    argocd_prod_syncauto
    sleep 10
    argocd app list
    argocd_logout
  fi
  return 0
}

mission_app_backup_rds_only () {
  get_option
  if [[ "${OPTION}" == "scaledown"  ]]; then
    argocd_login
    argocd_prod_syncoff
    argocd_app_syncoff
    scale_down_deploy_and_stateful
    argocd_logout
  fi
  if [[ "${OPTION}" == "backup"  ]]; then
    echo -e "${YELLOW}Backing up $UCAPP${NC}"
    rds_backup
  fi
  if [[ "${OPTION}" == "restore"  ]]; then
    echo -e "${YELLOW}Restoring $UCAPP${NC}"
    # RDS Restore Choice
    rds_restore
  fi
  if [[ "${OPTION}" == "scaleup"  ]]; then
    argocd_login
    scale_up_deploy
    argocd_app_syncauto
    #echo -e "${YELLOW}Commented out argocd_prod_sync - need to run manually if not doing anymore backups.${NC}"
    argocd_prod_syncauto
    sleep 10
    argocd app list
    argocd_logout
 fi
  return 0
}

# Main Script
#clear
checkUser
FLAG=1
while [ $FLAG -eq 1 ]
do
  chooseEnvironment
done

#argocd app list
#argocd app get "app name" --hard-refresh
#argocd app sync "app name" --force --prune

echo
echo -e "${GREEN} Script completed succesfully!${NC}"
echo
