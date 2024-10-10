#!/bin/bash


TIME=`cat cluster.yaml | head -5 | grep creationTimestamp: | awk '{ print $2}'`
CN=`cat cluster.yaml | head -5 | grep name: | awk '{ print $2}'`
export MAC=`curl -s http://$METADATA_IP/latest/meta-data/mac`
VPC_ID=`curl -s http://$METADATA_IP/latest/meta-data/network/interfaces/macs/$MAC/vpc-id `
#ZONES=`aws ec2 describe-subnets --filter Name=vpc-id,Values=$VPC_ID`
#echo $ZONES
if [ $SUBNETS == "NONE" ] ; then
 T_SUBNETS="\""`aws ec2 describe-subnets --filter Name=vpc-id,Values=$VPC_ID Name=tag:Name,Values="*Private*"| jq '.[] | .[] | .SubnetId' | xargs | sed s/\ /\",\"/g`"\""
 T_ZONES="\""`aws ec2 describe-subnets --filter Name=vpc-id,Values=$VPC_ID Name=tag:Name,Values="*Private*"| jq '.[] | .[] | .AvailabilityZone' | xargs | sed s/\ /\",\"/g`"\""
else
 T_SUBNETS=$SUBNETS
 Z_SEARCH=`echo $SUBNETS | sed s/\"//g | sed s/,/\ /g`
 #echo $Z_SEARCH
 T_ZONES="\""`aws ec2 describe-subnets --subnet-ids $Z_SEARCH | jq '.[] | .[] | .AvailabilityZone' | xargs | sed s/\ /\",\"/g`"\""
 #echo $T_ZONES
fi

BB_IP=`curl -s http://$METADATA_IP/latest/meta-data/local-ipv4`

echo "{"
echo "  \"cluster_name\": \"$CN\"",
echo "  \"timestamp\": $TIME",
echo "  \"aws_region\": \"$AWS_DEFAULT_REGION\"",
echo "  \"vpc_id\": \"$VPC_ID\"",
echo "  \"availability_zones\": [$T_ZONES]",
echo "  \"subnets\": [$T_SUBNETS]",
echo "  \"pub_key_file\": \"$CN-ssh.pub\"",
echo "  \"private_key_file\": \"$CN-ssh.pem\"",
echo "  \"bb_ip\": \"$BB_IP\"",
echo "  \"proxy\": \"$HTTP_PROXY\"",
echo "  \"ami_id\": \"ami-0b31f8deb81d3a290\"",
echo "  \"instance_arn\": \"arn:aws-us-gov:iam::584186918075:instance-profile/AFC2S_KONVOY\"",
echo "  \"metadata_ip\": \"$METADATA_IP\""
echo "}"

#  "availability_zones": ["us-gov-west-1a","us-gov-west-1b","us-gov-west-1c"]
#}

