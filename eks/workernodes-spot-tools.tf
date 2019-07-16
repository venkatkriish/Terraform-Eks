# This data source is included for ease of sample architecture deployment
# and can be swapped out as necessary.
data "aws_region" "current-region-spot-tools" {}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We implement a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html
locals {
  demo-nodegroup-spot-tools-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.demo.endpoint}' --b64-cluster-ca '${aws_eks_cluster.demo.certificate_authority.0.data}' '${var.cluster-name}' --kubelet-extra-args --node-labels='${var.spotk8s-toolstag}'='${var.spotk8s-toolskey}' --register-with-taints="${var.spotk8s-toolstag}"="${var.spotk8s-toolskey}":PreferNoSchedule
USERDATA
}

resource "aws_launch_template" "spottools" {
  count             = "${var.need-spot-tool-nodegroup}"
  name_prefix   = "spotnodegroupIG-tools"
  image_id      = "${data.aws_ami.eks-worker.id}"
  instance_type = "${var.spot-tools-instance-type-1}"
  network_interfaces {
    associate_public_ip_address = true
    security_groups = ["${aws_security_group.demo-node.id}"]
    
  }
  iam_instance_profile {
    name = "${aws_iam_instance_profile.demo-node.name}"
  }
  user_data          = "${base64encode(local.demo-nodegroup-spot-tools-userdata)}"
  lifecycle {
    create_before_destroy = true
  }
}
data "aws_ami" "eks-worker-nodegroup-spot-tools" {
  count             = "${var.need-spot-tool-nodegroup}"
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.demo.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

resource "aws_autoscaling_group" "spottoolsnodegroup" {
  vpc_zone_identifier = ["${var.nodes-subnet-ids}"]
  count             = "${var.need-spot-tool-nodegroup}"
  availability_zones = "${var.spot-asg-AGS}"
  desired_capacity   = "${var.spotASGdesired-tools}"
  max_size             = "${var.spotASGmax-tools}"
  min_size             = "${var.spotASGmin-tools}"
  name                 = "${var.cluster-name}-spot-tools-nodegroup"
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
  mixed_instances_policy {
    instances_distribution = {
      on_demand_base_capacity = 0
      on_demand_percentage_above_base_capacity = 0
    }
    launch_template {
      launch_template_specification {
        launch_template_id = "${aws_launch_template.spottools.id}"
        version = "$$Latest"
      }

      override {
        instance_type = "${var.spot-tools-instance-type-2}"
      }

      override {
        instance_type = "${var.spot-tools-instance-type-3}"
      }
    }
  }
}

locals {
  config_map_aws_auth_nodegroup_spot_tools = <<CONFIGMAPAWSAUTHnodegroupspot


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
CONFIGMAPAWSAUTHnodegroupspot
}

output "config_map_aws_auth_nodegroup_spot_tools" {
  value = "${local.config_map_aws_auth_nodegroup_spot_tools}"
}