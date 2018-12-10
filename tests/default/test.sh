#!/bin/sh
set -eo pipefail
tests_failed=0
cd terraform
terraform init
terraform apply --auto-approve
VPC_ID=`terraform output -json | jq -r '.vpc_id.value'`
subnet_count=`aws ec2 describe-subnets | jq --arg VPC_ID "$VPC_ID" '.Subnets[]| select (.VpcId==$VPC_ID)' | jq -s length`
terraform destroy --auto-approve

if [ $subnet_count -eq 3 ]
 then
   echo "√ Expected # of Subnets"
 else
   tests_failed=$((tests_failed+1))
fi


exit $tests_failed
