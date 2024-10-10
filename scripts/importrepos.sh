#!/bin/bash
#set -x

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

USER=`whoami`

if [ "$USER" != "git" ]; then
  echo "Script must be run as the git user"
  exit;
fi

mkdir -p /home/git/big-bang
cd /home/git/big-bang

#FOLDER=`ls -lrth /bootstrap/bb-core/ | grep "^d" | tail -1 | awk '{ print $9}'`
#FOLDER=`ls -lrth /bootstrap/bb-core/ | grep "^d" | awk '{ print $9}' | tail -n 1`
#BUNDLE_PATH=/bootstrap/bb-core/$FOLDER

ls -lrth /bootstrap/bb-core/ | grep "^d" | awk '{ print $9}'
read -p "Select BB version to Deploy : " FOLDER
yes_or_no "Do you wish to deploy BB: $FOLDER ? "

BUNDLE_PATH=/bootstrap/bb-core/$FOLDER
REPO_PATH=/home/git/repos

# clear /home/git/repos and extract repositories
rm -rf $REPO_PATH
tar -zxf $BUNDLE_PATH/repositories.tar.gz -C /home/git

# grab values.yaml
FN=`ls /$BUNDLE_PATH/bigbang* | sed 's%.*/%%' | sed s/\.tar\.gz//`
mkdir /tmp/umbrella
tar -C /tmp/umbrella -zxf /$BUNDLE_PATH/$FN.tar.gz

cd $REPO_PATH
for f in *; do
    if [ -d $f ] ; then
	echo "Importing $f"
        BASE=`echo $f`
        #echo $BASE
        #continue
        if [ ! -d /home/git/big-bang/$BASE ]; then
            BRANCH=`cat /tmp/umbrella/$FN/chart/values.yaml | grep -A 3 "repo.*$BASE\.git" | grep "tag" | tail -1 | awk '{ print $2}' | sed 's/"//g'`
            echo $BRANCH
        fi

	if [ ! -d /home/git/big-bang/$BASE ] ; then
            cd /home/git/big-bang
	    git clone ssh://git@$(hostname -i)/home/git/repos/$f
            cd $f
            git checkout tags/$BRANCH
            git branch odin
            git checkout odin
	    cd $REPO_PATH
	else
            cd /home/git/repos/$BASE
            MT=`git describe --tags $BRANCH`
            cd /home/git/big-bang/$BASE
	    git fetch --tags origin
            git merge $MT
            cd $REPO_PATH
        fi

    fi
done

FN2=`find /tmp/umbrella -maxdepth 1 -mindepth 1 -type d`
mv $FN2 /home/git/repos/umbrella

if [ ! -d /home/git/big-bang/umbrella ]; then
   mkdir /home/git/big-bang/umbrella
   cp -a /home/git/repos/umbrella /home/git/big-bang/
   cd /home/git/big-bang/umbrella
   git init .
   git add .
   git commit -m 'initial import'
fi

cd /home/git/repos/umbrella
git init
git add .
git commit -m 'initial import'


cd /home/git/big-bang/umbrella
git remote add origin /home/git/repos/umbrella
git pull origin master
git remote remove origin

cd /home/git/big-bang

for  f in * ; do
 if [ -d $f ] ; then
  #echo $f
  cd $f
  git status | grep "conflict" > /dev/null
  if [ $?  -eq 0 ] ; then
      echo "Merge conflict detected in $f"
  fi
  cd ..
 fi
done


