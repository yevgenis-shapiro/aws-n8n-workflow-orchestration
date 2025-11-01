#!/bin/bash

efs_dns=${efs_dns}
mount_point=/mnt/efs
export TIMEOUT_FOR_SERVICES=120

# Install AWS EFS Utilities
#yum install -y amazon-efs-utils # Amazon ami has pre installed nfs utils

# Create mount directory
if [ ! -d $mount_point ]; then
    echo "creating mount directory."
    sudo mkdir -p $mount_point
fi

#=== FUNCTION ==================================================
# NAME: mountEFS
# DESCRIPTION: check aws efs server is ready
#=================================================================
mountEFS() {
	local n=0
	while :; do
		n=$(($n + 1))
		if [[ $n -ge $TIMEOUT_FOR_SERVICES ]]; then
			echo "check timeout for mount EFS"
            exit 1
		fi
		returnCode=`sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport $efs_dns:/ $mount_point`
		if [[ $returnCode -eq 0 ]] || [[ $returnCode -eq 32 ]]; then
            echo "Successfully mount EFS"
            echo "edit fstab so EFS automatically loads on reboot"
                sudo su -c "echo '$efs_dns:/ $mount_point nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0' >> /etc/fstab"
            break
        fi
        done
 }

#main
mountEFS
echo "Finish mounting volumes Successfully."