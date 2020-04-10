// Generate Password
resource "random_string" "generate_rds_password" {
  length           = 12
  special          = true
  override_special = "!#$&"

  keepers = {
    kepeer1 = "${var.rds_pswd_keeper}"
  }
}

// Store Username & Password in SSM Parameter Store
resource "aws_ssm_parameter" "rds_username" {
  name        = "/${var.project}/mysql_username"
  description = "Master Username for RDS MySQL"
  type        = "String"
  value       = "${var.username}"

  tags = {
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}

resource "aws_ssm_parameter" "rds_password" {
  name        = "/${var.project}/mysql_pswd"
  description = "Master Password for RDS MySQL"
  type        = "SecureString"
  value       = random_string.generate_rds_password.result

  tags = {
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}

#####
# DB
#####
resource "aws_db_instance" "project" {
identifier = "${var.project}-db-server"

engine            = "${var.engine}"
engine_version    = "${var.engine_version}"
instance_class    = "${var.instance_class}"
allocated_storage = "${var.allocated_storage}"
storage_encrypted = false

name     = "dbinstance"
username = "${var.username}"
password = random_string.generate_rds_password.result

vpc_security_group_ids = [aws_security_group.project_rds_sg.id]

#maintenance_window = "Mon:00:00-Mon:03:00"
backup_window = "03:00-06:00"

# disable backups to create DB faster
backup_retention_period = "${var.backup_retention_period}"

tags = {
  Environment = "${var.env}"
  Project     = "${var.project}"
}

  # DB subnet group
  db_subnet_group_name = aws_db_subnet_group.project.id

  # Snapshot name upon DB deletion
  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.env}-${var.project}-db-server-snapshot"

  #timezone = "Eastern Standard Time"
}

resource "aws_db_subnet_group" "project" {
  name       = "db_subnet_group"
  subnet_ids = "${var.private_subnet_ids}"

  tags = {
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}

resource "aws_security_group" "project_rds_sg" {
  name   = "${var.project} RDS SG"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = "${var.db_allow_port}"
    to_port     = "${var.db_allow_port}"
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
