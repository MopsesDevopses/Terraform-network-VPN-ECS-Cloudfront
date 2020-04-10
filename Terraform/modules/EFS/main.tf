resource "aws_efs_file_system" "project" {
  creation_token = "${var.project}-EFS"

  tags = {
    Name        = "${var.project}-EFS"
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}

resource "aws_efs_mount_target" "project" {
  count           = length(var.private_subnet_id)
  file_system_id  = aws_efs_file_system.project.id
  subnet_id       = element(var.private_subnet_id, count.index)
  security_groups = [aws_security_group.project_efs_sg.id]
}

resource "aws_security_group" "project_efs_sg" {
  name   = "${var.project} EFS SG"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}
