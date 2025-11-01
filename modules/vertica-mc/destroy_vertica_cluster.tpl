#!/bin/bash

environment_prefix="${environment_prefix}"
vpc_id="${vpc_id}"
aws_key_pair="${aws_key_pair}"
aws_region="${aws_region}"

getVerticaInstanceIds() {
  vertica_inst_ids=$(aws ec2 --region "$aws_region" describe-instances --filters "Name=vpc-id,Values=$vpc_id" --query "Reservations[].Instances[?Tags[?Value==\`${environment_prefix}-vertica-db\`]] | [].InstanceId" --output text)
}

waitForVerticaInstancesTermination() {
  count=0
  while true; do
    if [ $count -gt 60 ]
    then
      echo "Timeout for waiting vertica instances be terminated."
      exit 1
    fi
    getVerticaInstanceIds
    if [ -z "$vertica_inst_ids" ]
    then
      echo "Vertica instances terminated"
      break
    else
      echo "Vertica instances are still running, please wait..."
      count=$((count + 1))
      sleep 10
    fi
  done
  sleep 120
}

terminateVerticaInstances() {
  getVerticaInstanceIds
  if [ -n "$vertica_inst_ids" ]
  then
    for vertica_inst_id in $vertica_inst_ids
    do
      echo "Disabling Termination protection of Vertica instance: $vertica_inst_id"
      aws ec2 --region "$aws_region" modify-instance-attribute --no-disable-api-termination --instance-id "$vertica_inst_id"
    done
    echo "Terminating Vertica instances: $vertica_inst_ids"
    aws ec2 --region "$aws_region" terminate-instances --instance-ids $vertica_inst_ids
    waitForVerticaInstancesTermination
  else
    echo "Vertica instances not found"
  fi
}


getVerticaSecurityGroupIds() {
  vertica_sg_ids=$(aws ec2 --region "$aws_region" describe-security-groups --filters "Name=vpc-id,Values=$vpc_id" --query "SecurityGroups[?contains(GroupName,\`${aws_key_pair}\`)] | [].GroupId" --output text)
}

deleteVerticaSecurityGroups() {
  getVerticaSecurityGroupIds
  if [ -n "$vertica_sg_ids" ]
  then
    for vertica_sg_id in $vertica_sg_ids
    do
      echo "Deleting Vertica Security Group: $vertica_sg_id"
      aws ec2 --region "$aws_region" delete-security-group --group-id $vertica_sg_id
    done
    echo "Deleted Vertica Security Groups"
  else
    echo "Vertica Security Groups not found"
  fi
}

main() {
  terminateVerticaInstances
  deleteVerticaSecurityGroups
}

main