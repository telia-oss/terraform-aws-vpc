#!/bin/sh
set -eo pipefail

# for integers comparisons: checkCounts <testValue> <expectedValue> <testName>
checkCounts() {
 if [ $1 -eq $2 ]
 then
   echo "√ $3"
 else
   echo "✗ $3"
   tests_failed=$((tests_failed+1))
fi
}


tests_failed=0
cd terraform
terraform init
terraform apply --auto-approve
VPC_ID=`terraform output -json | jq -r '.vpc_id.value'`
subnet_count=`aws ec2 describe-subnets | jq --arg VPC_ID "$VPC_ID" '.Subnets[]| select (.VpcId==$VPC_ID)' | jq -s length`
terraform destroy --auto-approve

checkCounts $subnet_count 3 "Expected # of Subnets"

exit $tests_failed
