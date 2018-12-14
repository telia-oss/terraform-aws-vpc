#!/bin/sh
export DIR="${PWD}"
cd ${DIR}/secret-source/examples/default/terraform
terraform destroy --auto-approve
