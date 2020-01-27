#!/bin/bash

STACK_NAME=awsbootstrap
REGION=ap-southeast-2
CLI_PROFILE=awsbootstrap
EC2_INSTANCE_TYPE=t2.micro
AWS_ACCOUNT_ID=`aws sts get-caller-identity --profile awsbootstrap --query "Account" --output text`
CODEPIPELINE_BUCKET="$STACK_NAME-$REGION-codepipeline-$AWS_ACCOUNT_ID"

# This only needs to be run once
init_s3() {
    echo -e "\n\n=========== Deploying setup.yml ==========="

    aws cloudformation deploy \
        --region $REGION \
        --profile $CLI_PROFILE \
        --stack-name $STACK_NAME-setup \
        --template-file setup.yml \
        --no-fail-on-empty-changeset \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameter-overrides \
        CodePipelineBucket = $CODEPIPELINE_BUCKET
}

create_stack() {
    echo -e "\n\n=========== Deploying main.yml ==========="

    aws cloudformation deploy \
        --region $REGION \
        --profile $CLI_PROFILE \
        --stack-name $STACK_NAME \
        --template-file main.yml \
        --no-fail-on-empty-changeset \
        --capabilities CAPABILITY_NAMED_IAM \
        --parameter-overrides \
        EC2InstanceType=$EC2_INSTANCE_TYPE

    # If the deploy succeeded, show the DNS name of the created instance
    if [ $? -eq 0 ]; then
        aws cloudformation list-exports \
            --profile awsbootstrap \
            --query "Exports[?Name=='InstanceEndpoint'].Value"
    fi
}

check_stack() {
    aws cloudformation describe-stacks --stack-name $STACK_NAME
}

delete_stack() {
    echo "deleting stack '$STACK_NAME'"

    aws cloudformation delete-stack --stack-name $STACK_NAME
}

# ----------------------------------------------------------------------
# run stuff!

# create_stack
# check_stack
delete_stack
