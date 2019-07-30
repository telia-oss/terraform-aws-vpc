package module

import (
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/stretchr/testify/assert"
)

// Expectations for the VPC test suite.
type Expectations struct {
	CIDRBlock         string
	SubnetCIDRBlocks  map[string]bool
	AvailabilityZones []string
	NATGatewayCount   int
	IPV6Enabled       bool
	Tags              map[string]string
}

// RunTestSuite runs the test suite against the autoscaling group.
func RunTestSuite(t *testing.T, vpcID string, region string, expected Expectations) {
	var (
		vpc      *ec2.Vpc
		subnets  map[string]*ec2.Subnet
		gateways map[string]*ec2.NatGateway
		azs      map[string]struct{}
	)
	sess := NewSession(t, region)

	vpc = DescribeVPC(t, sess, vpcID)
	assert.Equal(t, expected.CIDRBlock, aws.StringValue(vpc.CidrBlock))
	assert.Equal(t, expected.IPV6Enabled, len(vpc.Ipv6CidrBlockAssociationSet) > 0)

	tags := GetVPCTags(vpc)
	for k, want := range expected.Tags {
		got, ok := tags[k]
		if assert.True(t, ok) {
			assert.Equal(t, want, got)
		}
	}

	subnets = DescribeVPCSubnets(t, sess, vpcID)
	for subnetCIDR, isPublic := range expected.SubnetCIDRBlocks {
		s, ok := subnets[subnetCIDR]
		if !ok {
			t.Errorf("expected to find subnet cidr: %s", subnetCIDR)
			continue
		}
		assert.Equal(t, isPublic, aws.BoolValue(s.MapPublicIpOnLaunch))
		assert.Equal(t, expected.IPV6Enabled, len(s.Ipv6CidrBlockAssociationSet) > 0)
		assert.Equal(t, expected.IPV6Enabled, aws.BoolValue(s.AssignIpv6AddressOnCreation))

		tags := GetSubnetTags(s)
		for k, want := range expected.Tags {
			got, ok := tags[k]
			if !ok {
				t.Errorf("expected to find tag for subnet: %s", k)
				continue
			}
			assert.Equal(t, want, got)
		}
	}

	azs = GetSubnetAZs(subnets)
	assert.Equal(t, len(expected.AvailabilityZones), len(azs))
	for _, az := range expected.AvailabilityZones {
		_, ok := azs[az]
		if !ok {
			t.Errorf("expected to find subnet in availability zone: %s", az)
		}
	}

	gateways = DescribeNATGateways(t, sess, vpcID)
	assert.Equal(t, expected.NATGatewayCount, len(gateways))
}

func NewSession(t *testing.T, region string) *session.Session {
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(region),
	})
	if err != nil {
		t.Fatalf("failed to create new AWS session: %s", err)
	}
	return sess
}

func DescribeVPC(t *testing.T, sess *session.Session, vpcID string) *ec2.Vpc {
	c := ec2.New(sess)

	out, err := c.DescribeVpcs(&ec2.DescribeVpcsInput{
		VpcIds: []*string{aws.String(vpcID)},
	})
	if err != nil {
		t.Fatalf("failed to describe vpc: %s", err)
	}

	var vpc *ec2.Vpc
	for _, v := range out.Vpcs {
		if id := aws.StringValue(v.VpcId); id != vpcID {
			t.Fatalf("wrong vpc id: %s", id)
		}
		vpc = v
	}
	return vpc
}

func GetVPCTags(vpc *ec2.Vpc) map[string]string {
	tags := make(map[string]string)
	for _, t := range vpc.Tags {
		tags[aws.StringValue(t.Key)] = aws.StringValue(t.Value)
	}
	return tags
}

func GetSubnetTags(subnet *ec2.Subnet) map[string]string {
	tags := make(map[string]string)
	for _, t := range subnet.Tags {
		tags[aws.StringValue(t.Key)] = aws.StringValue(t.Value)
	}
	return tags
}

func GetSubnetAZs(subnets map[string]*ec2.Subnet) map[string]struct{} {
	out := make(map[string]struct{})
	for _, s := range subnets {
		out[aws.StringValue(s.AvailabilityZone)] = struct{}{}
	}
	return out
}

func DescribeVPCSubnets(t *testing.T, sess *session.Session, vpcID string) map[string]*ec2.Subnet {
	c := ec2.New(sess)

	out, err := c.DescribeSubnets(&ec2.DescribeSubnetsInput{
		Filters: []*ec2.Filter{
			&ec2.Filter{
				Name:   aws.String("vpc-id"),
				Values: []*string{aws.String(vpcID)},
			},
		},
	})
	if err != nil {
		t.Fatalf("failed to describe subnets: %s", err)
	}

	subnets := make(map[string]*ec2.Subnet, len(out.Subnets))
	for _, subnet := range out.Subnets {
		subnets[aws.StringValue(subnet.CidrBlock)] = subnet
	}

	return subnets
}

func DescribeNATGateways(t *testing.T, sess *session.Session, vpcID string) map[string]*ec2.NatGateway {
	c := ec2.New(sess)

	out, err := c.DescribeNatGateways(&ec2.DescribeNatGatewaysInput{
		Filter: []*ec2.Filter{
			&ec2.Filter{
				Name:   aws.String("vpc-id"),
				Values: []*string{aws.String(vpcID)},
			},
		},
	})
	if err != nil {
		t.Fatalf("failed to describe nat gateways: %s", err)
	}

	gateways := make(map[string]*ec2.NatGateway)
	for _, gw := range out.NatGateways {
		gateways[aws.StringValue(gw.SubnetId)] = gw
	}

	return gateways
}
