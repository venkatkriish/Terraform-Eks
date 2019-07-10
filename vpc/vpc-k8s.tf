# VPC
resource "aws_vpc" "jd-k8s-vpc" {
  cidr_block       = "${var.vpc_cidr}"
  tags {
   KubernetesCluster = "${var.cluster_name}"
   Name              = "${var.cluster_name}"
   "kubernetes.io/cluster/"${var.cluster_name}"" = "owned"
 }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.jd-k8s-vpc.id}"
  tags {
    KubernetesCluster = "${var.cluster_name}"
    Name = "${var.cluster_name}"
    "kubernetes.io/cluster/"${var.cluster_name}"" = "owned"
  }
}
# creating nat gateways for private subnets

resource "aws_nat_gateway" "nat" {
    count = "${length(var.subnets_cidr)}"
    allocation_id = "${element(aws_eip.nat_eip.*.id,count.index)}"
    subnet_id      = "${element(aws_subnet.public.*.id,count.index)}"
    tags {
        KubernetesCluster = "${var.cluster_name}"
        Name = ""${var.aws_region}"${element(var.azs-variables-ps,count.index)}.${var.cluster_name}"
        "kubernetes.io/cluster/"${var.cluster_name}" = "owned"
    }
}

# Subnets : public
resource "aws_subnet" "public" {
  count = "${length(var.subnets_cidr)}"
  vpc_id = "${aws_vpc.jd-k8s-vpc.id}"
  cidr_block = "${element(var.subnets_cidr,count.index)}"
  availability_zone = "${element(var.azs,count.index)}"
  tags {
    AssociatedNatgateway  = "${element(var.natgatewayips,count.index)}"
    KubernetesCluster = "${var.cluster_name}"
    Name = "utility-"${var.aws_region}"${element(var.azs-variables-ps,count.index)}.${var.cluster_name}"
    SubnetType = "Utility"
    "kubernetes.io/cluster/"${var.cluster_name}"" = "owned"
    "kubernetes.io/role/elb" = "1"
  }
}


# Route table: attach Internet Gateway 
resource "aws_route_table" "public_rt" {
  vpc_id = "${aws_vpc.jd-k8s-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
  tags {
    KubernetesCluster = "${var.cluster_name}"
    Name = "${var.cluster_name}"
    "kubernetes.io/cluster/"${var.cluster_name}"" = "owned"
    "kubernetes.io/kops/role" = "public"
  }
}

# Route table association with public subnets
resource "aws_route_table_association" "a" {
  count = "${length(var.subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.public.*.id,count.index)}"
  route_table_id = "${aws_route_table.public_rt.id}"
}


# Subnets : private
resource "aws_subnet" "private" {
  count = "${length(var.private_subnets_cidr)}"
  vpc_id = "${aws_vpc.jd-k8s-vpc.id}"
  cidr_block = "${element(var.private_subnets_cidr,count.index)}"
  availability_zone = "${element(var.azs,count.index)}"
  tags {
    KubernetesCluster = "${var.cluster_name}"
    Name = ""${var.aws_region}"${element(var.azs-variables-ps,count.index)}.${var.cluster_name}"
    SubnetType = "Private"
    "kubernetes.io/cluster/"${var.cluster_name}"" = "owned"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Route table: attach Internet Gateway 


# Define the route table for private subnets
resource "aws_route_table" "route-nat" {
  count = "${length(var.private_subnets_cidr)}"
  vpc_id = "${aws_vpc.jd-k8s-vpc.id}"

  tags {
    KubernetesCluster = "${var.cluster_name}"
    Name = "private-"${var.aws_region}"${element(var.azs-variables-ps,count.index)}.${var.cluster_name}"
    "kubernetes.io/cluster/"${var.cluster_name}"" = "owned"
    "kubernetes.io/kops/role"  =  "private-"${var.aws_region}"${element(var.azs-variables-ps,count.index)}"
  }
}



# creating elastic ips for NAT gateways
resource "aws_eip" "nat_eip" {
  count = "${length(var.private_subnets_cidr)}"
  vpc      = true
  tags {
    KubernetesCluster = "${var.cluster_name}"
    Name = ""${var.aws_region}"${element(var.azs-variables-ps,count.index)}.${var.cluster_name}"
    "kubernetes.io/cluster/"${var.cluster_name}"" = "owned"

  }
}
resource "aws_route_table_association" "web-private-nat" {
  count = "${length(var.subnets_cidr)}"
  subnet_id      = "${element(aws_subnet.private.*.id,count.index)}"
  route_table_id = "${element(aws_route_table.route-nat.*.id,count.index)}"
  
}