# CloudFormation implementation

`template.yaml` implements the same network, routing, security, and compute task
as the Terraform modules. All commands below run from the repository root in
PowerShell. AWS credentials must be configured for profile `learner-lab`.

## Parameters and prerequisites

Defaults match `terraform/main.tf`: region `us-east-1` (selected by CLI), zone
`us-east-1a`, project `nt548-lab01`, VPC `10.0.0.0/16`, subnets `10.0.1.0/24` and
`10.0.2.0/24`, `t3.micro`, key pair `nt548-lab01-key`, SSH CIDR `125.235.233.10/32`.
The key pair must already exist in the selected region; use your own current SSH
CIDR and keep its private key locally. Instance types must support x86_64.

CloudFormation resolves an Amazon Linux 2023 x86_64 AMI through the AWS public SSM
parameter. Terraform searches the latest matching Amazon-owned AMI. Both select
AL2023, but the exact AMI may differ as releases change. `Ec2AmiId` reports the
selected image. The shared launch template enforces IMDSv2 and root disk settings.

To match Terraform's `aws_default_security_group`, a Lambda custom resource removes
all rules from this stack VPC's default security group and applies its tags.
By default the stack creates a narrowly scoped Lambda execution role, requiring
`CAPABILITY_IAM` and IAM creation permissions. It leaves the group restricted on
deletion; AWS deletes the group with its VPC.

If Learner Lab disallows IAM role creation, pass `ExistingLambdaRoleArn` with an
authorized existing role ARN. That role must trust `lambda.amazonaws.com`, allow
CloudWatch logging, `ec2:DescribeSecurityGroups`, and allow
`ec2:RevokeSecurityGroupIngress`, `ec2:RevokeSecurityGroupEgress`, and `ec2:CreateTags`
on the stack VPC's default group. Your deploying identity needs `iam:PassRole` for
that role and permissions to create the other stack resources. Confirm your lab's
role permissions; an existing role's name alone does not guarantee them.

## Validate and deploy

```powershell
aws cloudformation validate-template --template-body file://cloudformation/template.yaml --profile learner-lab --region us-east-1

aws cloudformation deploy --template-file cloudformation/template.yaml --stack-name nt548-lab01-cfn --capabilities CAPABILITY_IAM --parameter-overrides AllowedSshCidr=125.235.233.10/32 KeyName=nt548-lab01-key --profile learner-lab --region us-east-1
```

Replace the SSH CIDR as needed. To reuse an existing Lambda role, append
`ExistingLambdaRoleArn=arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_ROLE` to the
`--parameter-overrides` list. To preview without executing, append
`--no-execute-changeset` to the deploy command and review the resulting change set.
Changing region also requires a matching `AvailabilityZone` and regional key pair.

Deploying creates a separate copy of the infrastructure, even when Terraform's
resources already exist. Neither tool should manage the other tool's resources.

## Outputs and SSH

```powershell
aws cloudformation describe-stacks --stack-name nt548-lab01-cfn --query 'Stacks[0].Outputs' --output table --profile learner-lab --region us-east-1
```

Outputs correspond to Terraform's outputs: `VpcId`, `PublicSubnetId`,
`PrivateSubnetId`, `PublicEc2Id`, `PrivateEc2Id`, `PublicEc2Ip`, `PrivateEc2Ip`, and
`Ec2AmiId`. Use the IP outputs to fill in these commands:

```powershell
ssh -i path/to/nt548-lab01-key.pem ec2-user@PUBLIC_IP
ssh -i path/to/nt548-lab01-key.pem -o "ProxyCommand=ssh -i path/to/nt548-lab01-key.pem -W %h:%p ec2-user@PUBLIC_IP" ec2-user@PRIVATE_IP
```

The private instance reaches the internet through the NAT gateway. Neither
instance installs a web server; this matches the Terraform lab.

## Cleanup

```powershell
aws cloudformation delete-stack --stack-name nt548-lab01-cfn --profile learner-lab --region us-east-1
aws cloudformation wait stack-delete-complete --stack-name nt548-lab01-cfn --profile learner-lab --region us-east-1
```

This deletes only the CloudFormation deployment. For a Terraform deployment, use
`terraform -chdir=terraform destroy`. The custom resource's automatically created
CloudWatch log group may remain after stack deletion.

## AWS references

- [AL2023 AMI discovery](https://docs.aws.amazon.com/linux/al2023/ug/ec2.html)
- [Launch template metadata options](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-ec2-launchtemplate-metadataoptions.html)
- [CloudFormation security groups](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-resource-ec2-securitygroup.html)
