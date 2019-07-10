variable "aws_region" {
	default = "us-east-1"
}
variable "cluster_name" {
	default = "testcluster"
}

variable "vpc_cidr" {
	default = "10.20.0.0/16"
}

variable "subnets_cidr" {
	type = "list"
	default = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
}

variable "private_subnets_cidr" {
	type = "list"
	default = ["10.20.4.0/24", "10.20.5.0/24", "10.20.6.0/24"]
}
variable "azs" {
	type = "list"
	default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
variable "azs-variables-ps" {
	type = "list"
	default = ["a", "b", "c"]
}