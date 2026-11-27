# NT548 Lab 01: AWS infrastructure as code

Two implementations of the same lab:

- [terraform/](terraform/): original Terraform configuration and modules.
- [cloudformation/](cloudformation/): equivalent CloudFormation stack and deployment instructions.
- [images/](images/): existing lab diagrams.

Both create a VPC, one public and one private subnet in one availability zone,
an internet gateway, a public NAT gateway, route tables, and two Amazon Linux
2023 EC2 instances. SSH to the public instance is restricted to your CIDR;
SSH to the private instance is allowed from the public instance's security group.
Both instances use encrypted 8 GiB gp3 root volumes and require IMDSv2.
The VPC's default security group has no inbound or outbound rules.

## Terraform

Run from the repository root:

```powershell
terraform -chdir=terraform init
terraform -chdir=terraform validate
terraform -chdir=terraform plan -out=tfplan
terraform -chdir=terraform apply tfplan
```

The existing local state, backup, provider cache, lock file, and saved plan were
moved into `terraform/` together with the source. Resource addresses and relative
module paths are unchanged. Generate a fresh plan before applying; the old saved
plan is retained only as an existing local artifact. Do not commit state or plans.

Settings are in `terraform/main.tf` and `terraform/providers.tf`. The current
provider uses AWS profile `learner-lab` and region `us-east-1`.

## CloudFormation

See [cloudformation/README.md](cloudformation/README.md) for validation, deployment,
outputs, SSH, and cleanup commands.

These are independent deployments. Creating the CloudFormation stack creates new
resources; it does not migrate or take over the resources in Terraform state.
Use the owning tool to delete each deployment. EC2, NAT gateways, and public IPv4
addresses incur charges while provisioned.
