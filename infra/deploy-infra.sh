#!/bin/bash

STACK_NAME=awsbootstrap
REGION=ap-southeast-2
CLI_PROFILE=awsbootstrap
EC2_INSTANCE_TYPE=t2.micro

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
