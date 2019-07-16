package asg_test

import (
	"fmt"
	"testing"

	vpc "github.com/telia-oss/terraform-aws-vpc/test"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestDefaultExample(t *testing.T) {
	tests := []struct {
		description string
		directory   string
		name        string
		region      string
		expected    vpc.Expectations
	}{
		{
			description: "basic example",
			directory:   "../examples/basic",
			name:        fmt.Sprintf("vpc-basic-test-%s", random.UniqueId()),
			region:      "eu-west-1",
			expected: vpc.Expectations{
				CIDRBlock: "10.0.0.0/16",
				SubnetCIDRBlocks: map[string]bool{
					"10.0.0.0/20":  true,
					"10.0.16.0/20": true,
					"10.0.32.0/20": true,
				},
				AvailabilityZones: []string{
					"eu-west-1a",
					"eu-west-1b",
					"eu-west-1c",
				},
				NATGatewayCount: 0,
				IPV6Enabled:     true,
				Tags: map[string]string{
					"terraform":   "True",
					"environment": "dev",
				},
			},
		},
	}

	for _, tc := range tests {
		tc := tc // Source: https://gist.github.com/posener/92a55c4cd441fc5e5e85f27bca008721
		t.Run(tc.description, func(t *testing.T) {
			t.Parallel()
			options := &terraform.Options{
				TerraformDir: tc.directory,

				Vars: map[string]interface{}{
					"name_prefix": tc.name,
					"region":      tc.region,
				},

				EnvVars: map[string]string{
					"AWS_DEFAULT_REGION": tc.region,
				},
			}

			defer terraform.Destroy(t, options)
			terraform.InitAndApply(t, options)

			vpc.RunTestSuite(t,
				terraform.Output(t, options, "vpc_id"),
				tc.region,
				tc.expected,
			)
		})
	}
}
