export LOCATION="centralus"
export RESOURCE_GROUP="rg-aks-centralus"
export AKS_NAME="avaks-centralus"
export VNET_NAME="aks-vnet"
export VNET_ADDRESS_PREFIX="10.0.0.0/16"
export SUBNET_NAME="aks-subnet"
export SUBNET_ADDRESS_PREFIX="10.0.0.0/18"

az group create --name $RESOURCE_GROUP --location $LOCATION

az feature register --name KubeletDisk --namespace Microsoft.ContainerService

az network vnet create --resource-group $RESOURCE_GROUP --name $VNET_NAME --address-prefixes $VNET_ADDRESS_PREFIX --subnet-name $SUBNET_NAME --subnet-prefixes $SUBNET_ADDRESS_PREFIX
export SUBNET_ID=$(az network vnet subnet show --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --name $SUBNET_NAME --query id -o tsv)

az deployment group create --resource-group $RESOURCE_GROUP --template-file create-aks.bicep --parameter aksName=$AKS_NAME --parameter location=$LOCATION --parameter subnetId=$SUBNET_ID

az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --network-plugin azure \
    --network-plugin-mode overlay \
    --vnet-subnet-id $SUBNET_ID \
    --pod-cidr 192.168.0.0/16 \
    --network-dataplane cilium \
    --nodepool-name "system" \
    --node-count 1 \
    --node-vm-size Standard_D4ds_v5 \
    --node-osdisk-type Ephemeral \
    --dns-service-ip 10.2.0.10 \
    --service-cidr 10.2.0.0/24 \
    --generate-ssh-keys

az aks nodepool add --resource-group $RESOURCE_GROUP --cluster-name $AKS_NAME --name d64dsv4 --node-count 1 --node-vm-size Standard_D64ds_v4 --node-osdisk-type Ephemeral
az aks nodepool add --resource-group $RESOURCE_GROUP --cluster-name $AKS_NAME --name d64dsv5 --node-count 1 --node-vm-size Standard_D64ds_v5 --node-osdisk-type Ephemeral --node-osdisk-size 2040
az aks nodepool add --resource-group $RESOURCE_GROUP --cluster-name $AKS_NAME --name d64dsv6 --node-count 1 --node-vm-size Standard_D64ds_v6 --node-osdisk-type Ephemeral --node-osdisk-size 1700

#az aks nodepool delete --resource-group $RESOURCE_GROUP --cluster-name $AKS_NAME --name d64dsv6

az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing

kubectl get nodes -o wide

kubectl debug node/aks-d64dsv5-24837796-vmss000000 -it --image=ubuntu --profile=sysadmin

apt-get update
apt-get install -y fio

# OS Disk
fio --name=test --rw=randread --bs=4k --direct=1 --ioengine=libaio --iodepth=16 --size=30G --runtime=30 --numjobs=12 --group_reporting --filename=/host/tmp/testfile
fio --name=test --rw=randwrite --bs=4k --direct=1 --ioengine=libaio --iodepth=16 --size=30G --runtime=30 --numjobs=12 --group_reporting --filename=/host/tmp/testfile
fio --name=test --rw=randrw --bs=4k --direct=1 --ioengine=libaio --iodepth=16 --size=30G --runtime=30 --time_based --numjobs=12 --group_reporting --filename=/host/tmp/testfile

fio --name=test --rw=randread --bs=1M --direct=1 --ioengine=libaio --iodepth=16 --size=30G --runtime=30 --numjobs=4 --group_reporting --filename=/host/tmp/testfile
fio --name=test --rw=randwrite --bs=1M --direct=1 --ioengine=libaio --iodepth=16 --size=30G --runtime=30 --numjobs=4 --group_reporting --filename=/host/tmp/testfile
fio --name=test --rw=randrw --bs=1M --direct=1 --ioengine=libaio --iodepth=16 --size=30G --runtime=30 --numjobs=4 --group_reporting --filename=/host/tmp/testfile

# Temp Disk
fio --name=test --rw=randread --bs=4k --direct=1 --ioengine=libaio --iodepth=16 --size=30G --runtime=30 --numjobs=36 --group_reporting --filename=/host/mnt/testfile
fio --name=test --rw=randwrite --bs=4k --direct=1 --ioengine=libaio --iodepth=16 --size=30G --runtime=30 --numjobs=12 --group_reporting --filename=/host/mnt/testfile
fio --name=test --rw=randrw --bs=4k --direct=1 --ioengine=libaio --iodepth=16 --size=30G --runtime=30 --numjobs=12 --group_reporting --filename=/host/mnt/testfile

fio --name=test --rw=randread --bs=1M --direct=1 --ioengine=libaio --iodepth=16 --size=30G --runtime=30 --numjobs=4 --group_reporting --filename=/host/mnt/testfile
fio --name=test --rw=randwrite --bs=1M --direct=1 --ioengine=libaio --iodepth=16 --size=30G --runtime=30 --numjobs=4 --group_reporting --filename=/host/mnt/testfile
fio --name=test --rw=randrw --bs=1M --direct=1 --ioengine=libaio --iodepth=16 --size=30G --runtime=30 --numjobs=4 --group_reporting --filename=/host/mnt/testfile

# Create stripe of /nvme disks
lsblk
apt install -y mdadm
mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 /dev/nvme1n1 /dev/nvme2n1
mkfs.ext4 /dev/md0
mkdir -p /host/mnt
mount /dev/md0 /host/mnt

# Testing within a pod

kubectl apply -f ubuntu.yaml
kubectl get pods -o wide

kubectl exec -it ubuntu-67959865d8-kmfqd -- /bin/bash

apt-get update
apt-get install -y fio

fio --directory=/emptydir --name=tempfile.dat --direct=1 --ioengine=libaio --iodepth=64 --rw=read --bs=1024k --size=4G --numjobs=1 --time_based --runtime=3600 --group_reporting
fio --directory=/emptydir --name=tempfile.dat --direct=1 --ioengine=libaio --iodepth=64 --rw=randread --bs=4k --size=4G --numjobs=1 --time_based --runtime=1000 --group_reporting
fio --directory=/emptydir --name=tempfile.dat --direct=1 --ioengine=libaio --iodepth=64 --rw=write --bs=1024k --size=4G --numjobs=1 --time_based --runtime=10 --group_reporting
fio --directory=/emptydir --name=tempfile.dat --direct=1 --ioengine=libaio --iodepth=64 --rw=randwrite --bs=4k --size=4G --numjobs=1 --time_based --runtime=10 --group_reporting
