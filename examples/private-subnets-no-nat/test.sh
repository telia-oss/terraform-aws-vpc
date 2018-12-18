#!/bin/sh
set -eo pipefail

# for integer comparisons: checkCounts <testValue> <expectedValue> <testName>
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
if [ $1 == 'ci' ]
  then
  VPC_ID=`cat terraform-out/terraform-out.json | jq -r '.vpc_id.value'`
  else
  VPC_ID=`terraform output -json | jq -r '.vpc_id.value'`
fi

subnet_count=`aws ec2 describe-subnets | jq --arg VPC_ID "$VPC_ID" '.Subnets[]| select (.VpcId==$VPC_ID)' | jq -s length`
natgateway_count=`aws ec2 describe-nat-gateways | jq --arg VPC_ID "$VPC_ID" '.NatGateways[]| select (.VpcId==$VPC_ID)'| jq -s length`
egress_only_igw_count=`aws ec2 describe-egress-only-internet-gateways | jq --arg VPC_ID "$VPC_ID" '.EgressOnlyInternetGateways[]| select (.Attachments[].VpcId==$VPC_ID)'| jq -s length`

checkCounts $subnet_count 6 "Expected # of Subnets"
checkCounts $natgateway_count 0 "Expected # of NAT Gateways"
checkCounts $egress_only_igw_count 1 "Expected # of Internet Only Egress Gateways"

exit $tests_failed
