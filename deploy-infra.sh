#!/bin/bash

set -euo pipefail

CLI_PROFILE=awsbootstrap
EC2_INSTANCE_TYPE=t2.micro
GITHUB_ACCESS_TOKEN=$(cat ~/.github/aws-bootstrap-token)
GITHUB_OWNER=$(cat ~/.github/aws-bootstrap-owner)
GITHUB_REPO=$(cat ~/.github/aws-bootstrap-repo)
GITHUB_BRANCH=master
REGION=ap-southeast-2
STACK_NAME=awsbootstrap
SETUP_STACK_NAME=$STACK_NAME-setup

AWS_ACCOUNT_ID=`aws sts get-caller-identity --profile ${CLI_PROFILE} --query "Account" --output text`
CLOUDFORMATION_BUCKET="$STACK_NAME-$REGION-cfn-$AWS_ACCOUNT_ID"
CODEPIPELINE_BUCKET="$STACK_NAME-$REGION-codepipeline-$AWS_ACCOUNT_ID"

create_setup_stack() {
    echo -e "\n\n=========== Deploying setup.yml ==========="

    aws cloudformation deploy \
        --region $REGION \
        --profile $CLI_PROFILE \
        --stack-name $SETUP_STACK_NAME \
        --template-file setup.yml \
        --no-fail-on-empty-changeset \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameter-overrides \
            CodePipelineBucket=$CODEPIPELINE_BUCKET \
            CloudFormationBucket=$CLOUDFORMATION_BUCKET
}

package_main() {
    # put main template into the cloudformation s3 bucket
    echo -e "\n\n=========== Packaging main.yml ==========="
    
    mkdir -p ./cfn_output
    
    PACKAGE_ERR="$(aws cloudformation package \
        --region $REGION \
        --profile $CLI_PROFILE \
        --template main.yml \
        --s3-bucket $CLOUDFORMATION_BUCKET \
        --output-template-file ./cfn_output/main.yml 2>&1)"
    
    if ! [[ $PACKAGE_ERR =~ "Successfully packaged artifacts" ]]; then
        echo "ERROR while running 'aws cloudformation package' command:"
        echo $PACKAGE_ERR
        exit 1
    fi
}

create_stack() {
    package_main

    echo -e "\n\n=========== Deploying main.yml ==========="

    aws cloudformation deploy \
        --region $REGION \
        --profile $CLI_PROFILE \
        --stack-name $STACK_NAME \
        --template-file ./cfn_output/main.yml \
        --no-fail-on-empty-changeset \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameter-overrides \
        EC2InstanceType=$EC2_INSTANCE_TYPE \
        GitHubOwner=$GITHUB_OWNER \
        GitHubRepo=$GITHUB_REPO \
        GitHubBranch=$GITHUB_BRANCH \
        GitHubPersonalAccessToken=$GITHUB_ACCESS_TOKEN \
        CodePipelineBucket=$CODEPIPELINE_BUCKET

    # If the deploy succeeded, show the DNS name of the created instance
    if [ $? -eq 0 ]; then
        aws cloudformation list-exports \
            --profile awsbootstrap \
            --query "Exports[?ends_with(Name,'LBEndpoint')].Value"
    fi
}

check_stacks() {
    aws cloudformation describe-stacks --profile $CLI_PROFILE --stack-name $SETUP_STACK_NAME
    aws cloudformation describe-stacks --profile $CLI_PROFILE --stack-name $STACK_NAME
}

delete_stack() {
    echo "deleting stack '$STACK_NAME'"
    aws cloudformation delete-stack --profile $CLI_PROFILE --stack-name $STACK_NAME
}

delete_setup_stack() {
    echo "deleting stack '$SETUP_STACK_NAME'"
    aws cloudformation delete-stack --profile $CLI_PROFILE --stack-name $SETUP_STACK_NAME
}

# ----------------------------------------------------------------------
# run stuff!

create_setup_stack
create_stack
# check_stacks
# delete_stack
# delete_setup_stack
