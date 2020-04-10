data "aws_ami" "latest_ami_for_ECS" {
  owners      = ["591542846629"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-2.0.*-x86_64-ebs"]
  }
}

resource "aws_autoscaling_group" "project" {
  name                      = "ASG-main-server-${var.project}"
  max_size                  = "${var.asg_max_size}"
  min_size                  = "${var.asg_min_size}"
  desired_capacity          = "${var.asg_desired_capacity}"
  vpc_zone_identifier       = "${var.private_subnet_ids}"
  launch_configuration      = aws_launch_configuration.project.name
  health_check_type         = "ELB"
  health_check_grace_period = 600
  default_cooldown          = 600

  tags = [
    {
      key                 = "Environment"
      value               = "${var.env}"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "${var.project}"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "${var.project}-ECS-${var.env}"
      propagate_at_launch = true
    },
  ]
}


resource "aws_autoscaling_policy" "CPU-TEST-ScaleUP" {
  name = "ScaleUP"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.project.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpualarmUP" {
  alarm_name = "TEST-CPU(UP)"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "85"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.project.name}"
  }

alarm_description = "This metric monitor EC2 instance cpu utilization"
alarm_actions = ["${aws_autoscaling_policy.CPU-TEST-ScaleUP.arn}"]

tags = {
  Environment = "${var.env}_cpualarmUP"
  Project     = "${var.project}_cpualarmUP"
   }
}

resource "aws_autoscaling_policy" "CPU-TEST-ScaleDOWN" {
  name = "ScaleDOWN"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  autoscaling_group_name = "${aws_autoscaling_group.project.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpualarmDOWN" {
  alarm_name = "TEST-CPU(DOWN)"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "1"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "300"
  statistic = "Average"
  threshold = "40"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.project.name}"
  }
  alarm_description = "This metric monitor EC2 instance cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.CPU-TEST-ScaleDOWN.arn}"]

  tags = {
    Environment = "${var.env}_cpualarmDOWN"
    Project     = "${var.project}_cpualarmDOWN"
}
}


resource "aws_autoscaling_attachment" "project" {
  autoscaling_group_name = aws_autoscaling_group.project.id
  alb_target_group_arn   = aws_lb_target_group.project.arn
}

resource "aws_launch_configuration" "project" {
  name                 = "${var.project}-MAIN Server"
  image_id             = data.aws_ami.latest_ami_for_ECS.id
  instance_type        = "${var.type_instance}"
  security_groups      = ["${var.sg_id}"]
  iam_instance_profile = "${var.iam_name}"
  key_name             = "${var.key}"

  user_data = templatefile("./user_data/user_data_ecs.sh.tpl", {
    aws_ecs_cluster = "${var.cluster_name}"
#    efs_id          = "${var.efs_id}"
#    sg_ip           = aws_instance.storage-gateway-server.private_ip
  })

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
#    var.efs,
#    aws_instance.storage-gateway-server,
  ]
}

resource "aws_lb" "project" {
  name               = "${var.project}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${var.sg_id}"]
  subnets            = "${var.public_subnet_ids}"

  tags = {
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}

resource "aws_lb_target_group" "project" {
  name     = "${var.project}-lb-tg"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_lb_listener" "project" {
  load_balancer_arn = aws_lb.project.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.project.arn
    type             = "forward"
  }
}

### VPN
/*
data "aws_ami" "latest_ami_for_bh" {
  owners      = ["099720109477"]
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}
*/

resource "aws_launch_configuration" "project_bh" {
  name                 = "${var.project}-VPN"
  image_id             = "${var.ami_VPN}"
  instance_type        = "${var.type_instance_VPN}"
  security_groups      = ["${aws_security_group.project_bh.id}"]
  iam_instance_profile = "${var.iam_bastion_name}"
  key_name             = "${var.key}"

  user_data = templatefile("./user_data/user_data_vpn.sh.tpl", {
#  eip    = "${aws_eip.eip.id}",
  eip    = "eipalloc-0463ff33c28fc444b",
  region = "${var.region}"
  })
}

resource "aws_autoscaling_group" "project_bh" {
  name                 = "ASG-VPN-${var.project}"
  max_size             = "1"
  min_size             = "1"
  desired_capacity     = "1"
  vpc_zone_identifier  = "${var.public_subnet_ids}"
  launch_configuration = aws_launch_configuration.project_bh.name
  health_check_type    = "EC2"
  health_check_grace_period = 300

  tags = [
    {
      key                 = "Environment"
      value               = "${var.env}"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "${var.project}"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "${var.project}-VPN"
      propagate_at_launch = true
    },
  ]
}

/*
resource "aws_eip" "eip" {
  vpc   = true

  tags = {
    Name        = "EIP_for_${var.project}_VPN"
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}
*/
resource "aws_security_group" "project_bh" {
  name   = "${var.project} VPN SG"
  vpc_id = "${var.vpc_id}"

  dynamic "ingress" {
    for_each = ["22", "443", "943", "945", "1194"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
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

#===== Storage gateway
/*
resource "aws_instance" "storage-gateway-server" {
	ami                         = "ami-0859f19661167ba58"
	instance_type               = "m5a.xlarge"
	associate_public_ip_address = false
	key_name                    = "${var.key}"
	subnet_id                   = "${var.private_subnet_ids[1]}"
	vpc_security_group_ids      = ["${aws_security_group.project_storage_gateway.id}"]
	root_block_device {
      	    volume_size = 80
      	    volume_type = "gp2"
	}

  tags = {
    Name        = "${var.project}-Storage-Gateway"
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}

resource "aws_ebs_volume" "storage-gateway-server-cache-disk" {
    availability_zone = "us-east-2b"
    size              = 500
    encrypted         = false
    type              = "st1"

    tags = {
      Environment = "${var.env}"
      Project     = "${var.project}"
    }
}

resource "aws_volume_attachment" "storage-gateway-server-cache-disk-attach" {
  device_name = "/dev/xvdb"
  volume_id   = "${aws_ebs_volume.storage-gateway-server-cache-disk.id}"
  instance_id = "${aws_instance.storage-gateway-server.id}"
  #force_detach      = true
}

resource "aws_storagegateway_gateway" "storage-gateway" {
	gateway_ip_address = "${aws_instance.storage-gateway-server.private_ip}"
	gateway_name       = "${var.project}-Storage-Gateway"
	gateway_timezone   = "GMT"
	gateway_type       = "FILE_S3"

  tags = {
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}

data "aws_storagegateway_local_disk" "storage-gateway-data" {
	disk_path = "${aws_volume_attachment.storage-gateway-server-cache-disk-attach.device_name}"
	gateway_arn = "${aws_storagegateway_gateway.storage-gateway.arn}"

  depends_on = [
    aws_volume_attachment.storage-gateway-server-cache-disk-attach,
    aws_storagegateway_gateway.storage-gateway
  ]
}

resource "aws_storagegateway_cache" "storage-gateway-cache" {
	disk_id     = "${data.aws_storagegateway_local_disk.storage-gateway-data.id}"
	gateway_arn = "${aws_storagegateway_gateway.storage-gateway.arn}"
}

resource "aws_storagegateway_nfs_file_share" "nfs_share" {
	client_list  = ["10.0.0.0/16"]
	gateway_arn  = "${aws_storagegateway_gateway.storage-gateway.arn}"
	location_arn = "arn:aws:s3:::fec-archive"
	role_arn     = "${aws_iam_role.storage_gateway_role.arn}"

  tags = {
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}

resource "aws_security_group" "project_storage_gateway" {
  name   = "${var.project} Storage Gateway SG"
  vpc_id = "${var.vpc_id}"

  dynamic "ingress" {
    for_each = ["80", "20048", "22", "111", "443", "2049"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
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

resource "aws_iam_role" "storage_gateway_role" {
  name               = "storage_gateway_role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "storagegateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
tags = {
  Environment = "${var.env}"
  Project     = "${var.project}"
}
}

resource "aws_iam_role_policy" "storage_gateway_policy" {
  name   = "iam_storage_gateway_policy"
  role   = "${aws_iam_role.storage_gateway_role.name}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:GetAccelerateConfiguration",
                "s3:GetBucketLocation",
                "s3:GetBucketVersioning",
                "s3:ListBucket",
                "s3:ListBucketVersions",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": "arn:aws:s3:::fec-archive",
            "Effect": "Allow"
        },
        {
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:GetObjectVersion",
                "s3:ListMultipartUploadParts",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": "arn:aws:s3:::fec-archive/*",
            "Effect": "Allow"
        }
    ]
}
EOF
}
*/
