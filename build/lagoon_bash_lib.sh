#!/bin/bash

#USAGE: lagoon_deploy LAGOON_PROJECT LAGOON_ENVIRONMENT [GRAPHQL_ENDPOINT] [LAGOON_SSH_ENDPOINT] [LAGOON_SSH_ENDPOINT] [LAGOON_PORT]
#example using defaults `>lagoon_deploy umami-demo master` 

lagoon_deploy() {
	LAGOON_PROJECT=$1
	LAGOON_ENVIRONMENT=$2

	if [ -z "$LAGOON_PROJECT" ] | [ -z "$LAGOON_ENVIRONMENT" ]; then
		echo "Error: first two arguments required."
		echo "Usage: lagoon_deploy lagoon-project-name environment-name"
		echo "Exiting ...";
		exit 1;
	fi

	GRAPHQL_ENDPOINT=${3:-"https://api.lagoon.amazeeio.cloud/graphql"}
	LAGOON_SSH_ENDPOINT=${4:-"ssh.lagoon.amazeeio.cloud"}
	LAGOON_PORT=${5:-32222}

	JWT_PRE_CLEAN=$(ssh -p $LAGOON_PORT -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t lagoon@$LAGOON_SSH_ENDPOINT token)
	
	if [ ! $? = 0 ]; then 
		echo "Error: Issue connecting to SSH to get JWT, exiting ...";
		exit 2;
	fi

	JWT=$(echo "$JWT_PRE_CLEAN" | sed 's/\r//')


	AUTHHEADER="Authorization: Bearer $JWT"

	GRAPHQL_QUERY='{ "query": "mutation { deployEnvironmentLatest(input: { environment: { name: \"'"$LAGOON_ENVIRONMENT"'\" project: { name: \"'"$LAGOON_PROJECT"'\" } } }) }" }'

	RES=$(curl -X POST -H 'Content-Type: application/json' -H "$AUTHHEADER" -d ''"$GRAPHQL_QUERY"'' $GRAPHQL_ENDPOINT 2>/dev/null)

	echo $RES

	if [[ $RES =~ .*success* ]]; then 
		exit 0; 
	else
		exit 1;
	fi
}

