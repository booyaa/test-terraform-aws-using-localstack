#!/bin/sh

set -e

old_cwd=$(pwd)
cd infra
bucket_name=$(terraform output -raw bucket_name)
aws --endpoint-url http://localhost:4566 s3 rm --recursive s3://"$bucket_name" # clean up
terraform destroy -auto-approve
if [ -f out.plan ]; then
    rm out.plan
fi
cd "$old_cwd"
