#!/bin/bash
REGION=$1
MID_ROLE=$2
TARGET_ROLE=$3
SESSION_NAME=$4

unset AWS_SESSION_TOKEN
unset AWS_DEFAULT_REGION
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY

cred=$(aws sts assume-role --role-arn "$MID_ROLE" \
                           --role-session-name "$SESSION_NAME" \
                           --query '[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken]' \
                           --output text)

AWS_ACCESS_KEY_ID=$(echo "$cred" | awk '{ print $1 }')
AWS_SECRET_ACCESS_KEY=$(echo "$cred" | awk '{ print $2 }')
AWS_SESSION_TOKEN=$(echo "$cred" | awk '{ print $3 }')

cred=$(aws sts assume-role --role-arn "$TARGET_ROLE" \
                           --role-session-name "$SESSION_NAME" \
                           --query '[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken]' \
                           --output text)

AWS_ACCESS_KEY_ID=$(echo "$cred" | awk '{ print $1 }')
AWS_SECRET_ACCESS_KEY=$(echo "$cred" | awk '{ print $2 }')
AWS_SESSION_TOKEN=$(echo "$cred" | awk '{ print $3 }')

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_SESSION_TOKEN
