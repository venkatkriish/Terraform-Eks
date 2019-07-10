output "vpc_id" {
  value       = "${aws_vpc.eks-vpc.id}"
  description = "The ID of the VPC"
}
output "private-subnet-ids" {
  value = "${aws_subnet.private.*.id}"
  description = "The ID of the private subnets"
}
output "public-subnet-ids" {
  value = "${aws_subnet.public.*.id}"
  description = "The ID of the public subnets"
}