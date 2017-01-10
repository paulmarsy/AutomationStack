#!/bin/bash
apt-get -y update

# teamcity's docker mount points
mkdir /tmp/teamcity/
mkdir /tmp/teamcity/data
mkdir /tmp/teamcity/logs

# install mono - required for octopus calamari
apt-get -y install mono-complete 

# register the vm with octopus as a new ssh connection
apt-get -y install jq

serverUrl="#{OctopusHostHeader}"
apiKey="#{ApiKey}"

environment="TeamCity Stack"
machineName="TeamCity (Ubuntu Docker)"
roles="TeamCity Server (Linux)"

localIp=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
accountId="usernamepassword-tentacle-auth"
fingerprint=$(ssh-keygen -E md5 -l -f /etc/ssh/ssh_host_rsa_key.pub | cut -c10-56)

environmentId=$(wget --header="X-Octopus-ApiKey: $apiKey" -O- ${serverUrl}/api/environments | jq ".Items[] | select(.Name==\"${environment}\") | .Id" -r)

machineId=$(wget --header="X-Octopus-ApiKey: $apiKey" --post-data "{\"Endpoint\": {\"CommunicationStyle\":\"Ssh\",\"AccountId\":\"$accountId\",\"Host\":\"$localIp\",\"Port\":\"22\",\"Uri\":\"ssh://$localIp:22/\",\"Fingerprint\":\"$fingerprint\"},\"EnvironmentIds\":[\"$environmentId\"],\"Name\":\"$machineName\",\"IsDisabled\":false,\"Uri\":null,\"Thumbprint\":null,\"TenantIds\":[],\"TenantTags\":[],\"Roles\":[\"$roles\"]}" -O- ${serverUrl}/api/machines | jq ".Id" -r)

healthTaskId=$(wget --header="X-Octopus-ApiKey: $apiKey" --post-data "{\"Name\":\"Health\",\"Description\":\"Check $machineName health\",\"Arguments\":{\"Timeout\":\"00:05:00\",\"MachineIds\":[\"$machineId\"]}}" -O-  ${serverUrl}/api/tasks | jq ".Id" -r)