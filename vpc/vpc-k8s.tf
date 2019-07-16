#global tags for VPC
locals {
  common_tags = {
    KubernetesCluster = "${var.cluster_name}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned" 
    "kubernetes.io/role/elb" = "1"
  }
}

#vpc creation

resource "aws_vpc" "jd-k8s-vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}"
    )
  )}"
}

#internetgateway creation

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.jd-k8s-vpc.id}"
}

#public subnet

resource "aws_subnet" "public" {
  count = "${length(var.subnets_cidr)}"
  vpc_id = "${aws_vpc.jd-k8s-vpc.id}"
  cidr_block = "${element(var.subnets_cidr,count.index)}"
  availability_zone = "${element(var.azs,count.index)}"
  map_public_ip_on_launch = true

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "utility-${var.aws_region}${element(var.azs-variables-ps,count.index)}.${var.cluster_name}",
      "AssociatedNatgateway", "${element(var.natgatewayips,count.index)}",
      "SubnetType", "Utility"
    )
  )}"
}

#private subnets

resource "aws_subnet" "private" {
  count = "${length(var.private_subnets_cidr)}"

  vpc_id = "${aws_vpc.jd-k8s-vpc.id}"
  cidr_block = "${element(var.private_subnets_cidr,count.index)}"
  availability_zone = "${element(var.azs,count.index)}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.aws_region}${element(var.azs-variables-ps,count.index)}.${var.cluster_name}",
      "SubnetType", "Private"
    )
  )}"
}

#public subent route
resource "aws_route" "public" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.igw.id}"
}

#public subnet route table

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.jd-k8s-vpc.id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}",
      "kubernetes.io/kops/role", "public"
    )
  )}"
}

#private route

resource "aws_route" "private" {
  count = "${length(var.private_subnets_cidr)}"

  route_table_id         = "${aws_route_table.private.*.id[count.index]}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat.*.id[count.index]}"
}

#private route table

resource "aws_route_table" "private" {
  count = "${length(var.private_subnets_cidr)}"

  vpc_id = "${aws_vpc.jd-k8s-vpc.id}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}",
      "kubernetes.io/kops/role", "public"
    )
  )}"
}
#private subnet associations

resource "aws_route_table_association" "private" {
  count = "${length(var.private_subnets_cidr)}"

  subnet_id      = "${aws_subnet.private.*.id[count.index]}"
  route_table_id = "${aws_route_table.private.*.id[count.index]}"
}

#public route table associations
resource "aws_route_table_association" "public" {
  count = "${length(var.subnets_cidr)}"

  subnet_id      = "${aws_subnet.public.*.id[count.index]}"
  route_table_id = "${aws_route_table.public.id}"
}



#
# NAT resources
#

resource "aws_eip" "nat" {
  count = "${length(var.subnets_cidr)}"

  vpc = true
}

resource "aws_nat_gateway" "nat" {
  count = "${length(var.private_subnets_cidr)}"

  allocation_id = "${aws_eip.nat.*.id[count.index]}"
  subnet_id     = "${aws_subnet.public.*.id[count.index]}"

  depends_on = ["aws_internet_gateway.igw"]

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "utility-${var.aws_region}${element(var.azs-variables-ps,count.index)}.${var.cluster_name}"
    )
  )}"
}