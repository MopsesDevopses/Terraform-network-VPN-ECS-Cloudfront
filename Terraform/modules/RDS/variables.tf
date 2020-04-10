variable "allocated_storage" {
  default = ""
}

variable "engine" {
  default = ""
}

variable "engine_version" {
  default = ""
}

variable "instance_class" {
  default = ""
}

variable "username" {
  default = ""
}

variable "backup_retention_period" {
  default = ""
}

variable "rds_pswd_keeper" {
  description = "Password keeper"
  default     = ""
}

variable "private_subnet_ids" {
  default = ""
}

variable "vpc_id" {
  default = ""
}

variable "db_allow_port" {
  default = ""
}

variable "env" {
  default = ""
}

variable "project" {
  default = ""
}

variable "sub_project" {
  default = ""
}
