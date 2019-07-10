# This data source is included for ease of sample architecture deployment
# and can be swapped out as necessary.
data "aws_region" "current-region" {}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We implement a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  demo-nodegroup-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.demo.endpoint}' --b64-cluster-ca '${aws_eks_cluster.demo.certificate_authority.0.data}' '${var.cluster-name}' --kubelet-extra-args --node-labels='${var.nodes-group-tag-first-arg}'='${var.nodes-group-tag-sec-arg}'
USERDATA
}

resource "aws_launch_configuration" "demo-ng-ondemand" {
  count             = "${var.need-nodegroup}"
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.demo-node.name}"
  image_id                    = "${data.aws_ami.eks-worker.id}"
  instance_type               = "${var.ondemandIGinstancetype}"
  name_prefix                 = "${var.cluster-name}"
  security_groups             = ["${aws_security_group.demo-node.id}"]
  user_data_base64            = "${base64encode(local.demo-nodegroup-userdata)}"

  lifecycle {
    create_before_destroy = true
  }
}
data "aws_ami" "eks-worker-nodegroup-ondemand" {
  count             = "${var.need-nodegroup}"
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.demo.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}
resource "aws_autoscaling_group" "demo-nodegroup-ondemand" {
  count             = "${var.need-nodegroup}"
  desired_capacity     = "${var.ondemandASGdesired}"
  launch_configuration = "${aws_launch_configuration.demo-ng-ondemand.id}"
  max_size             = "${var.ondemandASGmax}"
  min_size             = "${var.ondemandASGmin}"
  name                 = "${var.cluster-name}-nodegroup"
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
}

locals {
  config_map_aws_auth_nodegroup = <<CONFIGMAPAWSAUTHnodegroup


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
CONFIGMAPAWSAUTHnodegroup
}

output "config_map_aws_auth_nodegroup" {
  value = "${local.config_map_aws_auth_nodegroup}"
}