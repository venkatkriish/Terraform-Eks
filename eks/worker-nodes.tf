data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.demo.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}
resource "aws_autoscaling_group" "demo" {
  count             = "${var.need-defaultnodegroup}"
  desired_capacity     = "${var.defaultASGdesired}"
  launch_configuration = "${aws_launch_configuration.demo.id}"
  max_size             = "${var.defaultASGmax}"
  min_size             = "${var.defaultASGmin}"
  name                 = "${var.cluster-name}"
  vpc_zone_identifier  = ["${var.nodes-subnet-ids}"]
  tag {
    key                 = "Name"
    value               = "${var.cluster-name}"
    propagate_at_launch = true
  }
  tag {
    key  = "kubernetes.io/cluster/${var.cluster-name}"
    value = "owned"
    propagate_at_launch = true
  }
  tag {
    key  = "k8s.io/role/node"
    value = "1"
    propagate_at_launch = true
  }
  

#   tag {
#     key                 = "Name"
#     value               = "${var.cluster-name}"
#     propagate_at_launch = true
#   }

#   tag {
#    "kubernetes.io/cluster/${var.cluster-name}" = "owned"
#     "k8s.io/role/node" = "1"
#     propagate_at_launch = true
#   }
}

locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.demo-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH
}

output "config_map_aws_auth" {
  value = "${local.config_map_aws_auth}"
}