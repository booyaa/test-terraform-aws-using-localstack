#!/bin/sh

set -e
old_cwd=$(pwd)
cd infra
terraform init
terraform plan -out "out.plan"
terraform apply "out.plan"
cd "$old_cwd"
