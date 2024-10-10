#!/bin/bash

# Set path for AWS API tools packages
export AWS_PATH=/opt/aws
export PATH=$PATH:$AWS_PATH/bin:/usr/local/bin

aws configure set default.region us-gov-west-1

if [ -z "${JAVA_HOME}" ]; then
    if [ -d /usr/java/latest ]; then
        # prefer third-party JDK if present
        export JAVA_HOME=/usr/java/latest
    elif [ -d /usr/lib/jvm/java ]; then
        export JAVA_HOME=/usr/lib/jvm/java
    elif [ -d /usr/lib/jvm/jre ]; then
        export JAVA_HOME=/usr/lib/jvm/jre
    fi
fi

# Source environment variables for each set of tools

for aws_product in $(find /opt/aws/apitools /opt/aws/amitools -maxdepth 1 -type l 2>/dev/null); do
    [ -e $aws_product/environment.sh ] && source $aws_product/environment.sh
done

# Move logs over to S3 bucket
aws s3 mv /var/log/ s3://odin-log-cluster/`hostname`/`date +%Y%m%d`/ --recursive --exclude "*" --include "messages" --include "secure*"

aws s3 mv /var/log/kubernetes/audit/ s3://odin-log-cluster/`hostname`/`date +%Y%m%d`/ --recursive --exclude "*" --include "kube-apiserver-audit"

aws s3 mv /var/log/flb-storage/ s3://odin-log-cluster/`hostname`/`date +%Y%m%d`/flb-storage --recursive --include "*"

touch /var/log/lastlog

journalctl --vacuum-size=50M


