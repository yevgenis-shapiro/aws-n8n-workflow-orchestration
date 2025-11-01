EFS_HOST=${efs_dns}
EFS_MOUNT_POINT=/mnt/efs

SUITE_VOL_PATH=$${1:-/var/vols/itom/suite}
SUITE_VOLS=$${2:-vol0,vol1,vol2,vol3,vol4,vol5,vol6,vol7,vol8,vol9}
SUITE_VOL_STORAGE=$${3:-5}
SUITE_USER_ID=$${4:-1999}
SUITE_GROUP_ID=$${5:-1999}
PV_STORAGE_CLASS_NAME=$${6:-cdf-default}
PV_RECLAIM_POLICY=$${7:-Recycle}

SUITE_PVYAML=suite-pv.yaml
rm -rf $SUITE_PVYAML

#Create the path and set permission here because create_volume does not set permission to top-level dir of the path
sudo mkdir -p $EFS_MOUNT_POINT/$SUITE_VOL_PATH
sudo chown -R $SUITE_USER_ID:$SUITE_USER_ID $EFS_MOUNT_POINT/$SUITE_VOL_PATH

SUITE_VOLS_LIST=$${SUITE_VOLS//,/ }
for VOL in $SUITE_VOLS_LIST; do
    cat >> $SUITE_PVYAML<<EOL
apiVersion: v1
kind: PersistentVolume
metadata:
  name: $VOL
spec:
  accessModes:
  - ReadWriteMany
  capacity:
    storage: $${SUITE_VOL_STORAGE}Gi
  nfs:
    path: $SUITE_VOL_PATH/$VOL
    server: $EFS_HOST
  persistentVolumeReclaimPolicy: $PV_RECLAIM_POLICY
  storageClassName: $PV_STORAGE_CLASS_NAME
  volumeMode: Filesystem

---
EOL

    PATH_TO_FILE=$${0%/*}
    $PATH_TO_FILE/create_volume.sh $SUITE_USER_ID $SUITE_GROUP_ID $SUITE_VOL_PATH/$VOL
done

kubectl create -f $SUITE_PVYAML
echo "Created persistent volumes successfully"
