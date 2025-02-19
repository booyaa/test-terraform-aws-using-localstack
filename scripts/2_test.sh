#!/bin/bash

# shell change for $RANDOM

set -e

old_cwd=$(pwd)
cd infra

if [ -z "$AWS_ACCESS_KEY_ID"  ]; then
    export AWS_ACCESS_KEY_ID=mock_access_key
    export AWS_SECRET_ACCESS_KEY=mock_secret_key
    export AWS_DEFAULT_REGION=eu-west-2
fi

# create a random text file and upload to s3 to trigger lambda
bucket_name=$(terraform output -raw bucket_name)
temp_file="${RANDOM}.txt"
echo "hello world" > $temp_file
aws --endpoint-url http://localhost:4566 s3 cp $temp_file s3://"$bucket_name"/
aws --endpoint-url http://localhost:4566 s3 ls s3://"$bucket_name"/

# check logs for newly uploaded file
log_group_name=$(terraform output -raw log_group_name)
log_stream_name=$(aws --endpoint-url http://localhost:4566 \
                        logs describe-log-streams \
                        --log-group-name "$log_group_name" \
                        --query 'logStreams[0].logStreamName' --output text)
aws --endpoint-url http://localhost:4566 logs get-log-events \
    --log-group-name "$log_group_name" \
    --log-stream-name "$log_stream_name" --query 'events[*].[timestamp,message]' --output text

cd "$old_cwd"
