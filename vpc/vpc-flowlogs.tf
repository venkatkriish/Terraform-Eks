resource "aws_flow_log" "jd-k8s-vpc-logs" {
  iam_role_arn    = "${aws_iam_role.jd-k8s-vpc-role.arn}"
  log_destination = "${aws_cloudwatch_log_group.jd-k8s-vpc-cw.arn}"
  traffic_type    = "ALL"
  vpc_id          = "${aws_vpc.jd-k8s-vpc.id}"
}

resource "aws_cloudwatch_log_group" "jd-k8s-vpc-cw" {
  name = "jd-k8s-vpc-cw"
}

resource "aws_iam_role" "jd-k8s-vpc-role" {
  name = "jd-k8s-vpc-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "jd-k8s-vpc-policy" {
  name = "jd-k8s-vpc-policy"
  role = "${aws_iam_role.jd-k8s-vpc-role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}