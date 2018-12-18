#!/bin/sh
export DIR="${PWD}"
cd ${DIR}/secret-source/examples/default
terraform destroy --auto-approve
