provider "aws" {
  region     = "us-east-1"
}

module "platform-vpc" {
  #Replace the URL with the link of your module
  source = "s3::https://s3-eu-west-1.amazonaws.com/terraform-repo-ireland/vpck8s.zip"
  vpc_cidr = "192.20.0.0/16"
  cluster_name = "platform-eks"
  aws_region = "us-east-1"
  subnets_cidr = ["192.20.0.0/22", "192.20.4.0/22", "192.20.8.0/22"]
  private_subnets_cidr = ["192.20.32.0/19", "192.20.64.0/19", "192.20.96.0/19"]
  azs = ["us-east-1a","us-east-1b","us-east-1c"]
}
module "platform-eks" {
  #Replace the URL with the link of your module
  source = "s3::https://s3-eu-west-1.amazonaws.com/terraform-repo-ireland/eks-cluster.zip"
  cluster-name = "platform-eks"
  master-sg-vpc = "${module.platform-vpc.vpc_id}"
  master-subnet-ids = "${module.platform-vpc.public-subnet-ids}"
  nodes-subnet-ids = "${module.platform-vpc.private-subnet-ids}"
  #enabling addons for eks cluster
  enable_dashboard = 1
  enable_kubectl = 1
  enable_dashboard = 1
  enable_kube2iam = 1
  #Ondemaon IG Creation
  need-nodegroup = false
  ondemandASGmin = 1
  ondemandASGmax = 5
  ondemandASGdesired = 1
  ondemandIGinstancetype = "t3.xlarge"
  nodes-group-tag-first-arg = "kops.k8s.io/instancegroup"
  nodes-group-tag-sec-arg = "tools"
  #Default Worker Node Creation
  need-defaultnodegroup = false
  defaultASGmax = 10
  defaultASGmin = 2
  defaultASGdesired = 2
  defaultASGinstancetypes = "c4.large"
  #Spot Node IG Creation
  need-spotnodegroup = false
  spot-asg-AGS = ["us-east-1a","us-east-1b","us-east-1c"]
  spot-instance-type-1 = "c5n.2xlarge"
  spot-instance-type-2 = "c5.4xlarge"
  spot-instance-type-3 = "m5.2xlarge"
  spotASGmin =2
  spotASGmax = 5
  spotASGdesired = 2
  spotk8stag = "kops.k8s.io/instancegroup"
  spotk8skey = "android"

  #SPOT Node IG Creation 

  need-spot-tool-nodegroup = true
  spot-asg-AGS = ["us-east-1a","us-east-1b","us-east-1c"]
  spot-tools-instance-type-1 = "m5.xlarge"
  spot-tools-instance-type-2 = "m5a.xlarge"
  spot-tools-instance-type-3 = "m5d.xlarge"
  spotASGdesired-tools =1
  spotASGmax-tools = 5
  spotASGmin-tools = 1
  spotk8s-toolstag = "kops.k8s.io/instancegroup"
  spotk8s-toolskey = "spottools"
}
