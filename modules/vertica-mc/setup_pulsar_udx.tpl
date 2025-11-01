#!/bin/bash

environment_prefix="${environment_prefix}"
vpc_id="${vpc_id}"
aws_region="${aws_region}"
vertica_username="${vertica_username}"
vertica_password="${vertica_password}"
vertica_database_name="${vertica_database_name}"
vertica_ro_username="${vertica_ro_username}"
vertica_ro_password="${vertica_ro_password}"
vertica_rw_username="${vertica_rw_username}"
vertica_rw_password="${vertica_rw_password}"
IFS=',' read -r -a pulsar_udx_file <<< "${pulsar_udx_file}"
skip_dbinit="${skip_dbinit}"

install_cmd="export VERTICA_HOME=/opt/vertica && export VERTICA_DBA=${vertica_username} && export VERTICA_DBA_PASS=${vertica_password} && export VERTICA_DB=${vertica_database_name} && export VERTICA_RO_USER=${vertica_ro_username} && export VERTICA_RO_PASSWD=${vertica_ro_password} && export VERTICA_RW_USER=${vertica_rw_username} && export VERTICA_RW_PASSWD=${vertica_rw_password} && sudo --preserve-env=VERTICA_HOME,VERTICA_DBA,VERTICA_DB,VERTICA_RO_USER,VERTICA_RO_PASSWD,VERTICA_RW_USER,VERTICA_RW_PASSWD,VERTICA_DBA_PASS sh /usr/local/itom-di-pulsarudx/bin/dbinit.sh"

vertica_host=$(aws ec2 --region "$aws_region" describe-instances --filters "Name=vpc-id,Values=$vpc_id" --query "Reservations[].Instances[?Tags[?Value==\`${environment_prefix}-vertica-db\`]] | [].PrivateIpAddress | [0]"  --output text)

if [ -n "$vertica_host" ]
then
  echo "Pulsar udx setup started on node: $vertica_host"
  ssh-keyscan "$vertica_host" >> ~/.ssh/known_hosts

  os_version=$(ssh -n -A "$vertica_username"@"$vertica_host" "grep  -oP '\(Red.+?\)' /proc/version | grep -oP '[0-9]+\.[0-9]+' | head -1") || exit 1
  echo "RHEL version is $os_version"
  echo "Copying pulsar udx for OS version  $os_version"
  if (( $(echo "$os_version < 8.0" | bc -l) )); then
    pulsar_udx=$(printf "%s\n" "$${pulsar_udx_file[@]}" | grep -m1 "RHEL")
    echo "Pulsar UDX file is $pulsar_udx"
  else
    pulsar_udx=$(printf "%s\n" "$${pulsar_udx_file[@]}" | grep -v "RHEL"| grep -m1 "")
    echo "Pulsar UDX file is $pulsar_udx"
  fi

  scp "$HOME/itom-software/$pulsar_udx" "$vertica_username"@"$vertica_host":/home/"$vertica_username"/
  echo "Copied file $pulsar_udx to $vertica_host"
  echo "Installing the package"
  ssh -n -A "$vertica_username"@"$vertica_host" "sudo rpm -ivh $pulsar_udx"  || exit 1
  [ "${skip_dbinit}" == "false" ] && ssh -n -A "$vertica_username"@"$vertica_host" "$install_cmd"
  echo "Pulsar udx setup completed successfully"
else
  echo "Vertica nodes not found"
  echo "Pulsar udx setup failed"
  exit 1
fi
