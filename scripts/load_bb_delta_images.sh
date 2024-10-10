#!/bin/bash
#set -x

USER=`whoami`

if [ "$USER" != "maintuser" ]; then
  echo "Script must be run as the maintuser user"
  exit;
fi

# Setup working directory
WORKING_DIR=/home/maintuser/image_import
mkdir -p $WORKING_DIR

#check for $1
if [ $# -ne 1 ] ; then
 echo "usage: load_bb_delta_images.sh /path/to/image/file"
 echo "ex. /bootstrap/scripts/load_bb_delta_images.sh /bootstrap/bb-core-deltapackages/bigbang_1.0_1.1.tar.gz"
 exit
fi


echo "Extracting $1"
tar -zxf $1 -C $WORKING_DIR
chmod -R u+x $WORKING_DIR
echo "Finished extracting $1"

C_HOST=`cat $WORKING_DIR/var/lib/registry/synker.yaml | yq r - destination.registry.hostname`
C_PORT=`cat $WORKING_DIR/var/lib/registry/synker.yaml | yq r - destination.registry.port`

# Remove docker.io image references
RNUM=`cat $WORKING_DIR/var/lib/registry/synker.yaml | yq r - source.images | wc -l`
echo "$RNUM Packages included in package"
echo "Removing docker.io packages"
cat $WORKING_DIR/var/lib/registry/synker.yaml | grep docker.io
sed -i '/.*docker\.io.*/d' $WORKING_DIR/var/lib/registry/synker.yaml

RNUM=`cat $WORKING_DIR/var/lib/registry/synker.yaml | yq r - soruce.images | wc -l`
echo "$RNUM Remaning images to be imported"

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
