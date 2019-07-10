provider "aws" {
  region     = "eu-west-1"
}

module "infravpc" {
  #Replace the URL with the link of your module
  source = "./vpc"
  vpc_cidr = "10.20.0.0/16"
  aws_region = "eu-west-1"
  subnets_cidr = ["10.20.0.0/22", "10.20.4.0/22", "10.20.8.0/22"]
  private_subnets_cidr = ["172.20.32.0/19", "172.20.64.0/19", "172.20.96.0/19"]
  azs = ["eu-west-1a","eu-west-1b","eu-west-1c"]
}
module "jd-eks-tools" {
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