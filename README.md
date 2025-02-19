# Using localstack to test Terraformed AWS infra

Heavily borrowed from the talentedly @Adefemi [localstack-terraform](https://github.com/adefemi171/localstack-terraform) demo. I just added a few helpers to make it easier to run.

## Check localstack is running

```sh
# terminal 1 - spin up localstack
docker compose up -d # maybe need to rerun as it may fail the first time on MacOS
docker compose logs -f

# optional: install localstack to validate the docker compose'd service is functional
brew install localstack/tap/localstack-cli
localstack config validate # check the service is functional

# terminal 2 - a quick "hello world" test using the AWS CLI
export AWS_ACCESS_KEY_ID=mock_access_key
export AWS_SECRET_ACCESS_KEY=mock_secret_key
export AWS_DEFAULT_REGION=eu-west-2
aws --endpoint-url http://localhost:4566 s3 ls
```

## Deploy infra to localstack and test

This script will deploy the infra to localstack via terraform.

```sh
./scripts/1_build_infra.sh
```

This script will:

- upload a test file to the s3 bucket this will trigger the lambda function to run
- grab the lambda logs

```sh
./scripts/2_test.sh
```

This script will remove the file from the bucket and destroy the infra

```sh
./scripts/3_clean_up.sh
```

## To clean up localstack

You must run the clean up script! Otherwise the the following command will fail: `docker compose down --volumes`
