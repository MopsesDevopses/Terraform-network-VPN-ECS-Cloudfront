resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs_instance_role-${var.project}"

  assume_role_policy = file("./policy_data/policy_data.json")

  tags = {
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}

resource "aws_iam_instance_profile" "ecs" {
  name = "ecs_instance_profile-${var.project}"
  role = "${aws_iam_role.ecs_instance_role.name}"
}

resource "aws_iam_role_policy_attachment" "ecs_ec2_role" {
  role       = "${aws_iam_role.ecs_instance_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role" "bastion_role" {
  name               = "iam_vpn_role-${var.project}"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
tags = {
  Environment = "${var.env}"
  Project     = "${var.project}"
}
}

resource "aws_iam_instance_profile" "bastion-node" {
  name = "iam_vpn-${var.project}"
  role = "${aws_iam_role.bastion_role.name}"
}

resource "aws_iam_role_policy" "bastion_eip_attach_policy" {
  name   = "iam_vpn_EIPAttachPolicy"
  role   = "${aws_iam_role.bastion_role.name}"
  policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "ec2:AssociateAddress",
                  "ec2:ModifyInstanceAttribute"
              ],
              "Resource": "*"
          }
      ]
}
EOF
}
