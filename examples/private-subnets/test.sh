#!/bin/sh
set -eo pipefail

# for integer comparisons: check_counts <testValue> <expectedValue> <testName>
check_counts() {
 if [ $1 -eq $2 ]
 then
   echo "√ $3"
 else
   echo "✗ $3"
   tests_failed=$((tests_failed+1))
fi
}
tests_failed=0
if [ $1 == 'ci' ]
  then
  VPC_ID=`cat terraform-out/terraform-out.json | jq -r '.vpc_id.value'`
  export AWS_DEFAULT_REGION=eu-west-1
  else
  VPC_ID=`terraform output -json | jq -r '.vpc_id.value'`
fi

subnet_count=`aws ec2 describe-subnets | jq --arg VPC_ID "$VPC_ID" '.Subnets[]| select (.VpcId==$VPC_ID)' | jq -s length`
natgateway_count=`aws ec2 describe-nat-gateways | jq --arg VPC_ID "$VPC_ID" '.NatGateways[]| select (.VpcId==$VPC_ID)'| jq -s length`

check_counts $subnet_count 6 "Expected # of Subnets"
check_counts $natgateway_count 3 "Expected # of NAT Gateways"

exit $tests_failed