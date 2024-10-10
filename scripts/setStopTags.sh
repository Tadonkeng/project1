export CLUSTER_HEX=`cat /konvoy_setup/state/terraform.tfstate | grep hex | awk -F\" '{ print $4}'`
export CLUSTER_NODES=`aws ec2 describe-instances --filter Name=tag:konvoy\/clusterName,Values="*$CLUSTER_HEX*" | jq  '.[] | .[] | .Instances | .[] .InstanceId' |  xargs`
aws ec2 create-tags --resources $CLUSTER_NODES --tags Key=AutoStop,Value=true
