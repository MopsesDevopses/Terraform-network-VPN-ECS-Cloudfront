provider "aws" {
  region = "${var.region}"
}

#=================================S3 backend====================================

terraform {
  backend "s3" {
    bucket = "terraform-laboratory"          // Bucket where to SAVE Terraform State
    key    = "prod/terraform.tfstate"             // Object name in the bucket to SAVE Terraform State
    region = "eu-central-1"                         // Region where bycket created
  }
}

#======================================MAIN======================================

module "SG" {
  source      = "./modules/SecurityGroup"
  vpc_id      = "${module.network.vpc_id}"
  allow_ports = "${var.allow_ports}"
  env         = "${var.env}"
  project     = "${var.project}"
}

module "network" {
  source               = "./modules/network"
  vpc_cidr             = "${var.vpc_cidr}"
  public_subnet_cidrs  = "${var.public_subnet_cidrs}"
  private_subnet_cidrs = "${var.private_subnet_cidrs}"
  env                  = "${var.env}"
  project              = "${var.project}"
}

module "EC2" {
  source               = "./modules/EC2"
  sg_id                = "${module.SG.sg_id}"
  vpc_id               = "${module.network.vpc_id}"
  public_subnet_ids    = "${module.network.public_subnet_ids}"
  private_subnet_ids   = "${module.network.private_subnet_ids}"
  iam_name             = "${module.IAM_for_EC2.iam_name}"
  iam_bastion_name     = "${module.IAM_for_EC2.iam_bastion_name}"
  cluster_name         = "${module.ECS.cluster_name}"
#  efs_id               = "${module.network.efs_id}"
#  efs                  = "${module.network.efs}"
  region               = "${var.region}"
  ami_VPN              = "${var.ami_VPN}"
  type_instance        = "${var.type_instance}"
  type_instance_VPN    = "${var.type_instance_VPN}"
  asg_max_size         = "${var.asg_max_size}"
  asg_min_size         = "${var.asg_min_size}"
  asg_desired_capacity = "${var.asg_desired_capacity}"
  key                  = "${var.key}"
  env                  = "${var.env}"
  project              = "${var.project}"
}

/*
module "EFS" {
  source      = "./modules/EFS"
  private_subnet_id    = "${module.network.private_subnet_ids}"
  env                  = "${var.env}"
  project              = "${var.project}"
  vpc_id               = "${module.network.vpc_id}"
}
*/

module "IAM_for_EC2" {
  source      = "./modules/IAM"
  env         = "${var.env}"
  project     = "${var.project}"
}

module "RDS" {
  source                  = "./modules/RDS"
  engine                  = "${var.engine}"
  engine_version          = "${var.engine_version}"
  instance_class          = "${var.instance_class}"
  allocated_storage       = "${var.allocated_storage}"
  username                = "${var.username}"
  rds_pswd_keeper         = "${var.rds_pswd_keeper}"
  backup_retention_period = "${var.backup_retention_period}"
  vpc_id                  = "${module.network.vpc_id}"
  private_subnet_ids      = "${module.network.private_subnet_ids}"
  db_allow_port           = "${var.db_allow_port}"
  env                     = "${var.env}"
  project                 = "${var.project}"
}

module "ECS" {
  source              = "./modules/ECS"
  lb_arn              = "${module.EC2.lb_arn}"
  lb                  = "${module.EC2.lb}"
  public_subnet_names = "${module.network.data_az}"
  count_container     = "${var.count_container}"
  name_container      = "${var.name_container}"
  port_container      = "${var.port_container}"
  env                 = "${var.env}"
  project             = "${var.project}"
  ecs_cluster_name    = "${var.ecs_cluster_name}"
  ecs_service_name    = "${var.ecs_service_name}"
  ecs_task_definition_family = "${var.ecs_task_definition_family}"
}
