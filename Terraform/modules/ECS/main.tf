resource "aws_ecs_cluster" "project" {
  name = "${var.ecs_cluster_name}"

  tags = {
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}

resource "aws_ecs_service" "project" {
  name            = "${var.ecs_service_name}"
  cluster         = "${aws_ecs_cluster.project.id}"
  task_definition = "${aws_ecs_task_definition.project.arn}"
  desired_count   = "${var.count_container}"
  /*
  deployment_controller {
    type = "CODE_DEPLOY"
  }
*/

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  load_balancer {
    target_group_arn = "${var.lb_arn}"
    container_name   = "${var.name_container}"
    container_port   = "${var.port_container}"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [${var.public_subnet_names}]"
  }
  depends_on = [
    var.lb,
  ]
  /*
  tags = {
    Environment = "${var.env}"
    Project     = "${var.project}"
    Sub_project = "${var.sub_project}"
  }
*/
}

resource "aws_ecs_task_definition" "project" {
  family                = "${var.ecs_task_definition_family}"
  container_definitions = file("./task-definitions/service.json")
/*
  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }
*/
  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [${var.public_subnet_names}]"
  }

  tags = {
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}
