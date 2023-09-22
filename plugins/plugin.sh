#!/bin/bash
set -eou pipefail

check_platform(){
    if [[ $DRONE == "true" ]]; then
        platform="droneci"
    fi
}

send_post_request(){
    payload="{\"project_name\":\"$DRONE_REPO_NAME\", \"${ENVIRONMENT}_version\":\"$version\"}"
    curl --request POST \
    --url http://$PLUGIN_API_DOMAIN_NAME/api/add_project/ \
    --header 'accept: application/json' \
    --header 'Content-Type: application/json' \
    --data "$payload"
}

get_env(){
    ENVIRONMENT=$DRONE_DEPLOY_TO
    if [[ -z $ENVIRONMENT ]]; then
        ENVIRONMENT="development"
    fi
}

get_semantic_version() {
    # Check if a dependency file exists and read its contents
    if [[ -e "./$PLUGIN_PROJECT_NAME/$PLUGIN_PROJECT_NAME'.csproj" ]]; then
        version=$(awk -F "[><]" '/<Version>/{a=$3}END{print a}' ./$PLUGIN_PROJECT_NAME/$PLUGIN_PROJECT_NAME.csproj)
    elif [[ -e "package.json" ]]; then
        version=$(grep -oP '"version": "\K.*?(?=")' package.json)
    elif [[ -e "pom.xml" ]]; then
        version=$(awk -F "[><]" '/<version>/{print $3;exit}' pom.xml)
    else
        echo "Error: could not find project configuration file"
        return 1
    fi
    # Check if the version matches the semantic versioning format
    if [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$ ]]; then
        echo "$version"
    else
        echo "Error: version is not in semantic versioning format"
        return 1
    fi
}

get_semantic_version