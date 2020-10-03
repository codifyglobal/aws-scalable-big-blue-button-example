#!/bin/bash
# Script handles the add and remove for Application Server instances into scalelite
# only for testing purposes

while getopts ":s:p:m:r:c:" opt; do
  case $opt in
    p) SECRET="$OPTARG"
    ;;
    s) SERVER="$OPTARG"
    ;;
    m) METHOD="$OPTARG"
    ;;
    r) REGION="$OPTARG"
    ;;
    c) ECSCLUSTER="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

TASK_ARN=$(aws ecs list-task-definitions --region $REGION | jq -r '[ .taskDefinitionArns[] | select(contains("scalelite-handle-server")) ] | last')
CLUSTER=$(aws ecs list-clusters --region $REGION | jq -r ".clusterArns[] | select(contains(\"$ECSCLUSTER\"))" )

if [[ $METHOD == "create" ]]; then
  COMMAND_STRING="id=\$(bin/rake servers:add[$SERVER,$SECRET] | tail -n 1 | sed 's/id: //g'); bin/rake servers:enable[\$id];"
fi

if [[ $METHOD == "delete" ]]; then
  COMMAND_STRING="id=\$(./bin/rake servers | grep -B 1 "$SERVER" | head -n 1 | sed 's/id: //g'); bin/rake servers:panic[\$id] && bin/rake servers:remove[\$id]"
fi



aws ecs run-task --task-definition "$TASK_ARN" --cluster "$CLUSTER" --region $REGION --overrides "{\"containerOverrides\": [{\"name\": \"scalelite-handle-server\",\"command\": [\"/bin/sh\", \"-c\", \"$COMMAND_STRING\"]}]}"