## Autoscaling group

Easy way of setting up an autoscaling group which supports rolling updates, which takes care of creating:


- [Autoscaling group](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-as-group.html) in Cloudformation with support for rolling updates.
- [Launch configuration](https://www.terraform.io/docs/providers/aws/r/launch_configuration.html)
- [Security group](https://www.terraform.io/docs/providers/aws/r/security_group.html) with egress all.
- [IAM instance profile](https://www.terraform.io/docs/providers/aws/r/iam_instance_profile.html).

