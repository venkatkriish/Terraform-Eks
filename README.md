# Terraform-Eks
This is the repo for terraform EKS cluster

[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fvenkatkriish%2FTerraform-Eks.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fvenkatkriish%2FTerraform-Eks?ref=badge_shield)

| Branch | Build status                                                                                                                                                      |
| ------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| master | [![Build Status](https://travis-ci.org/venkatkriish/Terraform-Eks.svg?branch=master)](https://travis-ci.org/venkatkriish/Terraform-Eks)

## Assumptions

* You want to create an EKS cluster and an autoscaling group of workers for the cluster.
* You want these resources to exist within security groups that allow communication and coordination. These can be user provided or created within the module.
* You've created a Virtual Private Cloud (VPC) and subnets where you intend to put the EKS resources.
* If `manage_aws_auth = true`, it's required that both [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl) (>=1.10) and [`aws-iam-authenticator`](https://github.com/kubernetes-sigs/aws-iam-authenticator#4-set-up-kubectl-to-use-authentication-tokens-provided-by-aws-iam-authenticator-for-kubernetes) are installed and on your shell's PATH.


## Usage example

A full example leveraging other community modules is contained in the [examples/basic directory](https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/examples/basic). Here's the gist of using it via the Terraform registry:
```
module "eks-cluster" {
  #Replace the URL with the link of your module
  source = "./eks"
  cluster-name = "testcluster"
  master-sg-vpc = "${module.infravpc.vpc_id}"
  master-subnet-ids = "${module.infravpc.public-subnet-ids}"
  nodes-subnet-ids = "${module.infravpc.private-subnet-ids}"
  need-nodegroup = true
  ondemandASGmin = 1
  ondemandASGmax = 2
  ondemandASGdesired = 1
  ondemandIGinstancetype = "m4.2xlarge"
  need-defaultnodegroup = true
  defaultASGmax = 10
  defaultASGmin = 2
  defaultASGdesired = 2
  defaultASGinstancetypes = "c4.large"
  need-spotnodegroup = true
  spot-asg-AGS = ["eu-west-1a","eu-west-1b","eu-west-1c"]
  spot-instance-type-1 = "m4.2xlarge"
  spot-instance-type-2 = "m5a.xlarge"
  spot-instance-type-3 = "m5d.xlarge"
  spotASGmin =2
  spotASGmax = 5
  spotASGdesired = 2
  spotk8stag = "instance_type"
  spotk8skey = "spotinstances"
  nodes-group-tag-first-arg = "instance_type"
  nodes-group-tag-sec-arg = "ondemand"

}
```
## Other documentation

- [Autoscaling](docs/autoscaling.md): How to enable worker node autoscaling.
- [Enable Docker Bridge Network](docs/enable-docker-bridge-network.md): How to enable the docker bridge network when using the EKS-optimized AMI, which disables it by default.

