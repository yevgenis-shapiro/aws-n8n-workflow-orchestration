#!/bin/bash

efs_dns=${efs_dns}
suite_user_uid=$1
suite_user_gid=$2
mount_point=/mnt/efs
export TIMEOUT_FOR_SERVICES=120


# Create mount directory
if [ ! -d $mount_point ]; then
    echo "creating mount directory."
    sudo mkdir -p $mount_point
fi

 #=== FUNCTION ==================================================
 # NAME: make_volume
 # DESCRIPTION: create mount volume
 #=================================================================
make_volume() {
	local volume=$1
	cd $mount_point
	local mounted_pv=$mount_point$volume
	if [ ! -d $mounted_pv ]; then
        sudo mkdir -p $mounted_pv
    fi
	sudo chown -R $suite_user_uid:$suite_user_gid $mounted_pv
	sudo chmod g+w $mounted_pv
	sudo chmod g+s $mounted_pv
	echo "Successfully make volume: $volume"
}

#main
make_volume $3
echo "Finish making all volumes Successfully."