#!/bin/bash

kubectl_download_location=${kubectl_download_location}
kubectl_checksum_download_location=${kubectl_checksum_download_location}
eks_cluster_name=${eks_cluster_name}
eks_cluster_region=${eks_cluster_region}

echo "Downloading Kubernetes client"
curl -o kubectl $kubectl_download_location
if [ $? -ne 0 ]; then
  echo "Downloading Kubernetes client failed"
  exit 1;
fi

echo "Downloading Kubernetes client checksum"
curl -o kubectl.sha256 $kubectl_checksum_download_location
if [ $? -ne 0 ]; then
  echo "Downloading Kubernetes client checksum failed"
  exit 1;
fi

kubectl_checksum=$(openssl sha1 -sha256 kubectl | awk '{print $2}')
downloaded_checksum=$(awk '{print $1}' kubectl.sha256)

if [ "$kubectl_checksum" = "$downloaded_checksum" ]; then
  echo "Kubernetes client checksum verified"
else
  echo "Kubernetes client checksum verification failed. Aborting installation."
  exit  1
fi

chmod +x ./kubectl

mv ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin

echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc

echo "Configuring Kubernetes client"
aws eks update-kubeconfig --region $eks_cluster_region --name $eks_cluster_name
chmod go-r ~/.kube/config

echo "Configuring Kubernetes client for Root user"
#for CDF installation to proceed properly
sudo cp $HOME/bin/kubectl /usr/bin
sudo aws eks update-kubeconfig --region $eks_cluster_region --name $eks_cluster_name
