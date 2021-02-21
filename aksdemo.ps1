#Create a cluster using Kubenet in a bring your own subnet
#https://docs.microsoft.com/en-us/azure/aks/configure-kubenet
#az account List-locations
#az vm list-skus --location southcentralus -o tsv
az account list --output table
az account set --subscription "Azure Production Subscription"

az ad sp create-for-rbac --skip-assignment
VNET_ID=$(az network vnet show --resource-group RG-aks-andreas --name VNet-Infra-SCUS --query id -o tsv)
SUBNET_ID=$(az network vnet subnet show --resource-group RG-aks-andreas --vnet-name VNet-Infra-SCUS --name AKSKubeSubnet --query id -o tsv)

az role assignment create --assignee "<appid>" --scope $VNET_ID --role "Network Contributor"

az aks create \
    --resource-group RG-aks-andreas \
    --name AKS-demo-andreas \
    --location southcentralus \
    --node-count 1 \
    --node-vm-size Standard_B2s \
    --network-plugin kubenet \
    --service-cidr 10.7.0.0/16 \
    --dns-service-ip 10.7.0.10 \
    --pod-cidr 10.244.0.0/16 \
    --docker-bridge-address 172.17.0.1/16 \
    --vnet-subnet-id $SUBNET_ID \
    --service-principal "<appid>" \
    --client-secret "<secret>" \
    --generate-ssh-keys


az aks get-credentials --resource-group RG-AKS --name aks-ussc-demoandreas
az aks get-credentials --resource-group RG-aks-andreas --name AKS-demo-andreas

#View service principal for cluster
az aks show --resource-group RG-AKS --name aks-ussc-demoandreas --query servicePrincipalProfile.clientId
az ad sp show --id (az aks show --resource-group RG-AKS --name aks-ussc-demoandreas --query servicePrincipalProfile.clientId)

#Install aksdemo then have to update path to include it
az aks install-cli

#Open a browser to the kubernetes for a cluster
az aks browse --resource-group RG-aks-andreas --name AKS-demo-andreas

aksdemo cluster-info
aksdemo get nodes

#Add ACI as virtual node for AKS cluster
az aks enable-addons -g RG-AKS -n aks-ussc-demoandreas --addons virtual-node --subnet-name ACISubnet

#Connect the registry to the AKS cluster
az aks update -g RG-AKS -n aks-ussc-demoandreas --attach-acr andreasdemo

aksdemo apply -f aks-andreasdemo.yaml

aksdemo get pods -o wide
aksdemo get pods --show-labels
aksdemo get service
aksdemo describe svc azure-andreas-demo
#note the endpoints for the frontend points to the IP of the frontend pod IP
aksdemo get endpoints azure-andreas-demo


#General other
aksdemo get service --all-namespaces
#delete deployment
aksdemo delete  -f aks-andreasdemo.yaml


#https://docs.microsoft.com/en-us/azure/aks/start-stop-cluster
az aks stop --resource-group RG-aks-andreas --name AKS-demo-andreas
az aks start --resource-group RG-aks-andreas --name AKS-demo-andreas