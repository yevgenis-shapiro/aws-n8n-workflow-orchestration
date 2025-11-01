#!/bin/bash

environment_prefix="${environment_prefix}"
vertica_mc_ip="${vertica_mc_ip}"
vertica_mc_port="${vertica_mc_port}"
vertica_mc_db_admin="${vertica_mc_db_admin}"
vertica_mc_db_admin_password="${vertica_mc_db_admin_password}"
aws_region="${aws_region}"
aws_key_pair="${aws_key_pair}"
aws_cidr_range="${aws_cidr_range}"
vertica_database_name="${vertica_database_name}"
vertica_username="${vertica_username}"
vertica_password="${vertica_password}"
number_of_nodes=${number_of_nodes}
subnet_id="${subnet_id}"
aws_instance_type="${aws_instance_type}"
vertica_ami="${custom_ami}"
node_ip_setting="${node_ip_setting}"
tags="{\"name\":\"${environment_prefix}-vertica-db\",\"Deployment-ID\":\"${deployment-id}\"}"
vertica_license_file="~/itom-software/${vertica_license_file}"
vertica_node_data_volume_type=${vertica_node_data_volume_type}
vertica_node_data_volume_size=${vertica_node_data_volume_size}
vertica_node_data_volume_iops=${vertica_node_data_volume_iops}
vertica_node_catalog_volume_type=${vertica_node_catalog_volume_type}
vertica_node_catalog_volume_size=${vertica_node_catalog_volume_size}
vertica_node_catalog_volume_iops=${vertica_node_catalog_volume_iops}
vertica_node_temp_volume_type=${vertica_node_temp_volume_type}
vertica_node_temp_volume_size=${vertica_node_temp_volume_size}
vertica_node_temp_volume_iops=${vertica_node_temp_volume_iops}
vertica_mode="${vertica-mode}"
eon_mode_string="${eon_mode_string}"
communal_location_url="${communal_location_url}"

loginToVerticaMC() {
  curl --insecure --request POST \
  --data 'username='"$vertica_mc_db_admin"'&password='"$vertica_mc_db_admin_password" \
  "https://${vertica_mc_ip}:${vertica_mc_port}/webui/login" \
  --cookie-jar VerticaMCCookie
}

uploadVerticaLicense() {
  if [ -f "$vertica_license_file" ]
  then
    license_status=$(
    curl --insecure --request POST --header 'Accept:application/json' \
    --form file=@"$vertica_license_file" \
    "https://${vertica_mc_ip}:${vertica_mc_port}/webui/provisioning/license/upload" \
    --compressed --cookie VerticaMCCookie
    )
    echo "License upload status: $license_status"
    upload_status=$(echo "$license_status" | jq -r .status)
    license_id=$(echo "$license_status" | jq -r .licenseId)
    if [ "$upload_status" = "ok" ]
    then
      vertica_license_id=$license_id
    else
      echo "Failed to upload $vertica_license_file license file. Deploying Vertica Community Edition"
      vertica_license_id=-${number_of_nodes}
    fi
  else
    echo "$vertica_license_file license file does not exist. Deploying Vertica Community Edition"
    vertica_license_id=-${number_of_nodes}
  fi
}

buildClusterSetupRequestData() {
  cluster_setup_request_data='{
"awsAccessKeyID":"",
"awsSecretKey":"",
"clusterName":"AWSCluster",
"awsKeyPair":"'"$aws_key_pair"'",
"awsCidrRange":"'"$aws_cidr_range"'",
"verticaDatabaseName":"'"$vertica_database_name"'",
"verticaUserName":"'"$vertica_username"'",
"verticaPassword":"'"$vertica_password"'",
"numberOfNodes":'"$number_of_nodes"',
"awsEC2InstanceType":"'"$aws_instance_type"'",
"schemaVersion":"V2",
"dataPath":"/vertica/data",
"dataPathVolume":"EBS",
"dataPathVolumeNum":"8",
"dataPathVolumeType":"'"$vertica_node_data_volume_type"'",
"dataPathVolumeIOPS":'"$vertica_node_data_volume_iops"',
"dataPathVolumeSize":'"$vertica_node_data_volume_size"',
"dataPathVolumeEncrypted":false,
"depotPath":"/vertica/depot",
"depotPathVolume":"",
"depotPathVolumeNum":8,
"depotPathDevices":"",
"depotPathVolumeType":"gp2",
"depotPathVolumeIOPS":2000,
"depotPathVolumeSize":75,
"depotPathVolumeEncrypted":false,
"catalogPath":"/vertica/catalog",
"catalogPathVolume":"EBS",
"catalogPathVolumeNum":"1",
"catalogPathVolumeType":"'"$vertica_node_catalog_volume_type"'",
"catalogPathVolumeIOPS":'"$vertica_node_catalog_volume_iops"',
"catalogPathVolumeSize":'"$vertica_node_catalog_volume_size"',
"catalogPathVolumeEncrypted":false,
"tempPath":"/vertica/temp",
"tempPathVolume":"EBS",
"tempPathVolumeNum":"1",
"tempPathVolumeType":"'"$vertica_node_temp_volume_type"'",
"tempPathVolumeIOPS":'"$vertica_node_temp_volume_iops"',
"tempPathVolumeSize":'"$vertica_node_temp_volume_size"',
"tempPathVolumeEncrypted":false,
"cloudWatchEMail":"",
"eonModeStr":"'"$eon_mode_string"'",
"databaseModeStr":"'"$vertica_mode"'",
"communalLocationUrl":"'"$communal_location_url"'",
"eonDbShards":12,
"tagInstances":true,
"tags":'"$tags"',
"nodeIpSetting":"'"$node_ip_setting"'",
"paidDBProvisioning":false,
"subnet":"'"$subnet_id"'",
"ami":"'"$vertica_ami"'",
"isQuickCreateStr":"false",
"isTestDriveEnabledStr":"false",
"isCloudWatchEnabledStr":"false",
"licenseID":'"$vertica_license_id"'
}'
}

initiateVerticaClusterSetup() {
  cluster_setup_response=$(
    curl --insecure --request POST --header 'Accept:application/json' \
    --header 'Content-Type:application/json' --data "$cluster_setup_request_data" \
    "https://${vertica_mc_ip}:${vertica_mc_port}/webui/AWSProvisioning/initiateClusterSetup" \
    --cookie VerticaMCCookie
  )

  echo "cluster setup response:  $cluster_setup_response"

  cluster_setup_response_status=$(echo "$cluster_setup_response" | jq -r .status)
  if [ "$cluster_setup_response_status" != "ok" ]; then
    echo "Failed to create vertica database"
    exit 1
  fi
}

waitForVerticaClusterCreation() {
  count=0
  while true; do
    if [ $count -gt 360 ]
    then
      echo "Timeout for creating the vertica database."
      echo "The last response: $status"
      exit 1
    fi

    status=$(
      curl --insecure --request POST --header 'Accept:application/json' \
      "https://${vertica_mc_ip}:${vertica_mc_port}/webui/AWSProvisioning/clusterSetupProgress" \
      --cookie VerticaMCCookie
    )

    provisioningStatus=$(echo "$status" | jq -r .provisioningStatus)

    if [ "$provisioningStatus" = "PROVISIONING_FAILED" ]
    then
      echo "Failed to provision a Vertica DB. The last response: $status"
      exit 1
    elif [ "$provisioningStatus" = "PROVISIONING_COMPLETED" ]
    then
      echo "Successfully to create a vertica database cluster."
      break
    elif [ "$provisioningStatus" = "PROVISIONING_IN_PROGRESS" ]
    then
      echo "Please wait..., Status of creation is $provisioningStatus"
      count=$((count + 1))
      sleep 10
    else
      echo "Vertica Cluster Setup status:  $status"
      exit 1
    fi
  done

  echo "Final status of Vertica cluster setup:  $status"
}

main() {
  loginToVerticaMC
  uploadVerticaLicense
  buildClusterSetupRequestData
  initiateVerticaClusterSetup
  waitForVerticaClusterCreation
}

main