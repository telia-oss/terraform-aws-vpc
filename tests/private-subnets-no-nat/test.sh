#!/bin/sh
set -eo pipefail
tests_failed=0
cd terraform
terraform init
terraform apply --auto-approve
VPC_ID=`terraform output -json | jq -r '.vpc_id.value'`
subnet_count=`aws ec2 describe-subnets | jq --arg VPC_ID "$VPC_ID" '.Subnets[]| select (.VpcId==$VPC_ID)' | jq -s length`
natgateway_count=`aws ec2 describe-nat-gateways | jq --arg VPC_ID "$VPC_ID" '.NatGateways[]| select (.VpcId==$VPC_ID)'| jq -s length`

egress_only_igw_count=`aws ec2 describe-egress-only-internet-gateways | jq --arg VPC_ID "$VPC_ID" '.EgressOnlyInternetGateways[]| select (.Attachments[].VpcId==$VPC_ID)'| jq -s length`

terraform destroy --auto-approve

if [ $subnet_count -eq 6 ]
 then
   echo "√ Expected # of Subnets"
 else
   echo "✗ Expected # of Subnets"
   tests_failed=$((tests_failed+1))
fi

if [ $natgateway_count -eq 0 ]
 then
   echo "√ Expected # of Nat Gateways"
 else
   echo "✗ Expected # of Nat Gateways"
   tests_failed=$((tests_failed+1))
fi

if [ $egress_only_igw_count -eq 1 ]
 then
   echo "√ Expected # of Internet Only Egress Gateways"
 else
   echo "✗ Expected # of Internet Only Egress Gateways"
   tests_failed=$((tests_failed+1))
fi


exit $tests_failed