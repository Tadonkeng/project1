#!/bin/bash

USER=`whoami`

if [ "$USER" != "git" ]; then
  echo "Script must be run as the git user"
  exit;
fi 

#Setup Folders
mkdir -p /home/git/big-bang
mkdir -p /tmp/gather > /dev/null
cd /tmp/gather

# Clone Repositories
# Grab the values.yam with has the repo/branch combinations we need
curl -sLO https://repo1.dsop.io/platform-one/big-bang/umbrella/-/raw/master/chart/values.yaml

# Ugly, but the short of it is we grep a url/branch pair and clone that specific branch
# for each repo, the double awk/xargs is to reverse the order of the repo/banch for
# the git clone command
#cat values.yaml | grep -A 3 "repo:" | grep "repo:\|tag:"| awk '{ print $2}' | xargs -n 2 | awk '{ print $2"\n"$1 }' | xargs -n 2 git clone --single-branch --branch

#cat values.yaml | grep -A 3 "repo:" | awk '{ print $2}' | xargs -n 2 | awk '{ print $2"\n"$1 }' | xargs -n 2 git clone --single-branch --branch 
cat values.yaml | grep "repo:" | awk '{ print $2}' | xargs -n 1 git clone 
#| awk '{ print $2"\n"$1 }' | xargs -n 2 git clone --single-branch --branch 
git clone https://repo1.dsop.io/platform-one/big-bang/umbrella.git

# Make a folder for today, and clean it of any previous set of bundles
DS=`date '+%Y-%m-%d'`
mkdir -p /bootstrap/bb-core-v1/$DS
rm -f /bootstrap/bb-core-v1/$DS/*

# Need values.yaml we are basing this off of for use with import script
cp values.yaml /bootstrap/bb-core-v1/$DS/
# There will be a folder for ever repo we cloned so we iterate over them
for f in *; do
    if [ -d "$f" ]; then
        cd $f
        BRANCH=`cat /tmp/gather/values.yaml | grep -A 3 "repo.*$f\.git" | grep "tag" | tail -1 | awk '{ print $2}'`
        #BRANCH=`git branch | awk '{ print $2}'`
        echo $f $BRANCH
        git bundle create /bootstrap/bb-core-v1/$DS/$f.bundle --all --tags > /dev/null
        git bundle verify /bootstrap/bb-core-v1/$DS/$f.bundle > /dev/null
        cd ..
    fi
done

# cleanup
#rm -rf /tmp/gather/*
