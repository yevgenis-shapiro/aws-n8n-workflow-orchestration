#!/bin/bash

vertica_hosts="${vertica_hosts}"
vertica_host_ips="${vertica_host_ips}"
vertica_host_ip="${vertica_host_ip}"
vertica_dba_user="${vertica_dba_user}"
vertica_dba_password="${vertica_dba_password}"
vertica_license_file="${vertica_license_file}"
vertica_database_name="${vertica_database_name}"
vertica_ro_username="${vertica_ro_username}"
vertica_ro_password="${vertica_ro_password}"
vertica_rw_username="${vertica_rw_username}"
vertica_rw_password="${vertica_rw_password}"
vertica_dba_group="${vertica_dba_group}"
IFS=',' read -r -a pulsar_udx_file <<< "${pulsar_udx_file}"
skip_dbinit="${skip_dbinit}"
vertica_mode="${vertica-mode}"
vertica_shard_count="${vertica_shard_count}"
communal_location_url="${communal_location_url}"
vertica_timezone="${vertica_timezone}"
vertica_node_data_volume_size="${vertica_node_data_volume_size}"
multi_tenancy="${multi_tenancy}"


install_vertica() {
  vertica_license_file_path="$HOME/itom-software/$vertica_license_file"
  if [ -z "$vertica_license_file" ] || [ ! -f "$vertica_license_file_path" ]
  then
    echo "$vertica_license_file_path license file does not exist. Applying Vertica Community Edition license"
    vertica_license_file="CE"
  else
    scp "$vertica_license_file_path" "$vertica_dba_user"@"$vertica_host_ip":/home/"$vertica_dba_user"/
  fi

  echo "Vertica setup started on node: $vertica_host_ip"
  ssh -n -A "$vertica_dba_user"@"$vertica_host_ip" "sudo --preserve-env /opt/vertica/sbin/install_vertica --hosts $vertica_hosts --dba-user $vertica_dba_user --dba-user-password $vertica_dba_password --dba-group $vertica_dba_group --point-to-point --data-dir /vertica/data --license $vertica_license_file --accept-eula --failure-threshold FAIL"
  echo "Vertica setup completed on node: $vertica_host_ip"
}

create_db() {
  echo "Creating database: $vertica_database_name"
  if [ "$vertica_mode" = "Eon Mode" ]; then
    ssh -n -A "$vertica_dba_user"@"$vertica_host_ip" "/opt/vertica/bin/adminTools -t create_db -s $vertica_hosts -d $vertica_database_name -c /vertica/catalog -D /vertica/data -p $vertica_dba_password --communal-storage-location=$communal_location_url --depot-path=/vertica/data --shard-count=$vertica_shard_count"
  else
    ssh -n -A "$vertica_dba_user"@"$vertica_host_ip" "/opt/vertica/bin/adminTools -t create_db -s $vertica_hosts -d $vertica_database_name -c /vertica/catalog -D /vertica/data -p $vertica_dba_password"
  fi
}

enable_password_less_ssh() {
  ssh -n -A "$user_ip" "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa"
  ssh -n -A "$user_ip" "chmod 700 ~/.ssh"
  ssh -n -A "$user_ip" "chmod 600 ~/.ssh/*"
  ssh -n -A "$user_ip" "sudo yum install -y firewalld"
  ssh -n -A "$user_ip" "sudo systemctl mask firewalld"
  ssh -n -A "$user_ip" "sudo systemctl disable firewalld"
  ssh -n -A "$user_ip" "sudo systemctl stop firewalld"
  ssh -n -A "$user_ip" "sudo yum install -y chrony"
  ssh -n -A "$user_ip" "sudo systemctl start chronyd"
  ssh -n -A "$user_ip" "sudo systemctl enable chronyd"
  ssh -n -A "$user_ip" "echo 'export TZ=\"$vertica_timezone\"' | sudo tee -a /etc/profile"

  for ip in $vertica_host_ips
  do
    echo "vertica ip is $ip"
    ssh -n -A "$user_ip" "ssh-keyscan $ip  >> ~/.ssh/known_hosts"
    ssh -n -A "$user_ip" "cat ~/.ssh/id_rsa.pub | ssh -A $vertica_dba_user@$ip \"cat >> ~/.ssh/authorized_keys\""
  done
}

install_pulsar_udx() {

if [ "$multi_tenancy" == "true" ]
then
  echo "multi_tenancy is enabled"
  install_cmd="export VERTICA_HOME=/opt/vertica && export VERTICA_DBA=${vertica_dba_user} && export VERTICA_DBA_PASS=${vertica_dba_password}  && export VERTICA_DB=${vertica_database_name} && sudo --preserve-env=VERTICA_HOME,VERTICA_DBA,VERTICA_DB,VERTICA_DBA_PASS sh /usr/local/itom-di-pulsarudx/bin/dbinit.sh -o"
else
  install_cmd="export VERTICA_HOME=/opt/vertica && export VERTICA_DBA=${vertica_dba_user} && export VERTICA_DBA_PASS=${vertica_dba_password}  && export VERTICA_DB=${vertica_database_name} && export VERTICA_RO_USER=${vertica_ro_username} && export VERTICA_RO_PASSWD=${vertica_ro_password} && export VERTICA_RW_USER=${vertica_rw_username} && export VERTICA_RW_PASSWD=${vertica_rw_password} && sudo --preserve-env=VERTICA_HOME,VERTICA_DBA,VERTICA_DB,VERTICA_RO_USER,VERTICA_RO_PASSWD,VERTICA_RW_USER,VERTICA_RW_PASSWD,VERTICA_DBA_PASS sh /usr/local/itom-di-pulsarudx/bin/dbinit.sh"
fi

if [ -n "$vertica_host_ip" ]
then
  echo "Pulsar udx setup started on node: $vertica_host_ip"

  os_version=$(ssh -n -A "$vertica_dba_user"@"$vertica_host_ip" "grep  -oP '\(Red.+?\)' /proc/version | grep -oP '[0-9]+\.[0-9]+' | head -1") || exit 1
  echo "RHEL version is $os_version"
  echo "Copying pulsar udx for OS version  $os_version"
  if (( $(echo "$os_version < 8.0" | bc -l) )); then
    pulsar_udx=$(printf "%s\n" "$${pulsar_udx_file[@]}" | grep -m1 "RHEL")
    echo "Pulsar UDX file is $pulsar_udx"
  else
    pulsar_udx=$(printf "%s\n" "$${pulsar_udx_file[@]}" | grep -v "RHEL"| grep -m1 "")
    echo "Pulsar UDX file is $pulsar_udx"
  fi

  scp "$HOME/itom-software/$pulsar_udx" "$vertica_dba_user"@"$vertica_host_ip":/home/"$vertica_dba_user"/
  echo "Copied file $pulsar_udx to $vertica_host_ip"
  echo "Installing the package"
  ssh -n -A "$vertica_dba_user"@"$vertica_host_ip" "sudo rpm -ivh $pulsar_udx"  || exit 1
  [ "${skip_dbinit}" == "false" ] && ssh -n -A "$vertica_dba_user"@"$vertica_host_ip" "$install_cmd"
  echo "Pulsar udx setup completed successfully"
else
  echo "Vertica nodes not found"
  echo "Pulsar udx setup failed"
  exit 1
fi
}

combine_disk_containers_for_storage() {
  echo "Newly added disks:"
  ssh -n -A "$user_ip" "sudo fdisk -l"

  echo "Filtering root disk"
  root_disk=$(ssh -n -A "$user_ip" lsblk -oMOUNTPOINT,PKNAME -rn | awk '$1 ~ /^\/$/ { print $2 }')

  echo "Formatting a RAID-0 volume"
  ssh -n -A "$user_ip" "lsblk | grep 'disk' | grep '${vertica_node_data_volume_size}G' | grep -v '$root_disk' | head -n 8 | awk '{print \"/dev/\" \$1}' | xargs sudo mdadm --create /dev/md10 --level 0 --raid-devices=8"
  sleep 10s

  echo "Formatting the file system to ext4"
  ssh -n -A "$user_ip" "sudo mkfs.ext4 /dev/md10"

  new_uuid=$(ssh -n -A "$user_ip" "sudo blkid /dev/md10 | cut -d '\"' -f2")
  ssh -n -A "$user_ip" "echo \"UUID=$new_uuid /vertica/data ext4 defaults,nofail,nobarrier 0 2\" | sudo tee -a /etc/fstab"

  ssh -n -A "$user_ip" "sudo mount /dev/md10 /vertica/data"

  ssh -n -A "$user_ip" "echo '/sbin/blockdev --setra 8192 /dev/md10' | sudo tee -a /etc/rc.local"

  ssh -n -A "$user_ip" "sudo /sbin/blockdev --setra 8192 /dev/md10"

  ssh -n -A "$user_ip" "echo deadline | sudo tee /sys/block/md10/queue/scheduler"

  ssh -n -A "$user_ip" "sudo mkdir /vertica/catalog"
  ssh -n -A "$user_ip" "sudo mkdir /vertica/temp"

  ssh -n -A "$user_ip" "
    disks50_disk1=\$(lsblk | grep 'disk' | grep \"50G\" | grep -v '$root_disk' | awk '{print \"/dev/\" \$1}' | tail -n 1)
    disks50_disk2=\$(lsblk | grep 'disk' | grep \"50G\" | grep -v '$root_disk' | awk '{print \"/dev/\" \$1}' | tail -n 2 | head -n 1)

    echo \"First device: \$disks50_disk1\"
    echo \"Second device: \$disks50_disk2\"

    sudo mkfs.ext4 \"\$disks50_disk1\"
    sudo mkfs.ext4 \"\$disks50_disk2\"

    sudo mount \"\$disks50_disk1\" /vertica/catalog
    sudo mount \"\$disks50_disk2\" /vertica/temp

    # Set read-ahead for the first disk
    echo \"/sbin/blockdev --setra 2048 \$disks50_disk1\" | sudo tee -a /etc/rc.local
    sudo /sbin/blockdev --setra 2048 \"\$disks50_disk1\"

    # Set read-ahead for the second disk
    echo \"/sbin/blockdev --setra 2048 \$disks50_disk2\" | sudo tee -a /etc/rc.local
    sudo /sbin/blockdev --setra 2048 \"\$disks50_disk2\"

    disk1_basename=\$(basename \"\$disks50_disk1\")
    disk2_basename=\$(basename \"\$disks50_disk2\")

    echo deadline | sudo tee \"/sys/block/\$disk1_basename/queue/scheduler\"
    echo deadline | sudo tee \"/sys/block/\$disk2_basename/queue/scheduler\"

    # Retrieve UUID for /vertica/catalog and /vertica/temp and update /etc/fstab
    new_uuid_catalog=\$(sudo blkid -s UUID -o value \"\$disks50_disk1\")
    echo \"UUID=\$new_uuid_catalog /vertica/catalog ext4 defaults,nofail,nobarrier 0 2\" | sudo tee -a /etc/fstab

    new_uuid_temp=\$(sudo blkid -s UUID -o value \"\$disks50_disk2\")
    echo \"UUID=\$new_uuid_temp /vertica/temp ext4 defaults,nofail,nobarrier 0 2\" | sudo tee -a /etc/fstab
"

  echo "Listing all RAID volumes"
  ssh -n -A "$user_ip" "ls -l /dev/disk/by-uuid"

  ssh -n -A "$user_ip" "sudo chown $vertica_dba_user:verticadba /vertica/data"
  ssh -n -A "$user_ip" "sudo chown $vertica_dba_user:verticadba /vertica/catalog"
  ssh -n -A "$user_ip" "sudo chown $vertica_dba_user:verticadba /vertica/temp"

  ssh -n -A "$user_ip" "sudo chmod +x /etc/rc.d/rc.local"
}

main(){
  sleep 180
  for vertica_node_ip in $vertica_host_ips
  do
    echo "vertica node ip is $vertica_node_ip"
    vertica_host=$vertica_node_ip
    user_ip="$vertica_dba_user"@"$vertica_host"
    ssh-keyscan "$vertica_host" >> ~/.ssh/known_hosts
    enable_password_less_ssh
    combine_disk_containers_for_storage
  done
  install_vertica
  create_db
  install_pulsar_udx
}

main
