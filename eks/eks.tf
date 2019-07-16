resource "aws_eks_cluster" "demo" {
  name            = "${var.cluster-name}"
  role_arn        = "${aws_iam_role.demo-eks-cluster.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.demo-cluster.id}"]
    subnet_ids         = ["${var.master-subnet-ids}"]
  }
  enabled_cluster_log_types = ["api", "audit","authenticator","controllerManager","scheduler"]
  depends_on = [
    "aws_iam_role_policy_attachment.demo-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.demo-cluster-AmazonEKSServicePolicy",
    "aws_cloudwatch_log_group.example",
  ]
}
resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/eks/${var.cluster-name}/cluster"
  retention_in_days = 7
}