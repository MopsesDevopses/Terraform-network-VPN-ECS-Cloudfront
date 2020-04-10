data "aws_availability_zones" "az" {}

locals {
  az_list = join(", ", aws_subnet.public_subnets[*].availability_zone)
}

locals {
  private_subnet_id = join(", ", aws_subnet.private_subnets[*].id)
}

resource "aws_vpc" "project" {
  cidr_block       = "${var.vpc_cidr}"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Environment = "${var.env}"
    Project     = "${var.project}"
    Name = "${var.project}-VPC-${var.env}"
  }
}

resource "aws_internet_gateway" "project" {
  vpc_id = aws_vpc.project.id

  tags = {
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}

#=====Public Subnet

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.project.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = data.aws_availability_zones.az.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-public-subnet-${count.index + 1}"
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}

resource "aws_route_table" "project" {
  vpc_id = aws_vpc.project.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project.id
  }

  tags = {
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}

resource "aws_route_table_association" "rt_association" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.project.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}

#=====Private Subnet

resource "aws_subnet" "private_subnets" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.project.id
  cidr_block              = element(var.private_subnet_cidrs, count.index)
  availability_zone       = data.aws_availability_zones.az.names[count.index]

  tags = {
    Name = "${var.project}-private-subnet-${count.index + 1}"
    Environment = "${var.env}-private-subnet-${count.index + 1}"
    Project     = "${var.project}-private-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "project_private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.project.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    Environment = "${var.env}_private_rt"
    Project     = "${var.project}_private_rt"
  }
}

resource "aws_route_table_association" "rt_association_private" {
  count          = length(aws_subnet.private_subnets[*].id)
  route_table_id = aws_route_table.project_private[count.index].id
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
}
#===== NAT

resource "aws_eip" "nat" {
  count = length(var.private_subnet_cidrs)
  vpc   = true

  tags = {
    Name        = "${var.env}-nat-gw-${count.index + 1}"
    Environment = "${var.env}_nat_gw"
    Project     = "${var.project}_nat_gw"
  }
}

resource "aws_nat_gateway" "nat" {
  count         = length(var.private_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(aws_subnet.public_subnets[*].id, count.index)

  tags = {
    Name        = "${var.env}-nat-gw-${count.index + 1}"
    Environment = "${var.env}_nat_gw"
    Project     = "${var.project}_nat_gw"
  }
}

#===== endpoint
/*
resource "aws_vpc_endpoint" "project_endpoint" {
  vpc_id            = aws_vpc.project.id
  service_name      = "com.amazonaws.us-east-2.storagegateway"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    "${aws_security_group.project_endpoint.id}",
  ]

  #subnet_ids          = ["${aws_subnet.private_subnets.*.id}"]
  subnet_ids          = coalescelist(aws_subnet.private_subnets.*.id)
  private_dns_enabled = true

  tags = {
    Name        = "${var.project}-vpc-endpoint"
    Environment = "${var.env}"
    Project     = "${var.project}"
  }
}

resource "aws_security_group" "project_endpoint" {
  name   = "${var.project} VPC ENDPOINT SG"
  vpc_id = aws_vpc.project.id

  dynamic "ingress" {
    for_each = ["443", "1026", "1027", "1028", "1031", "2222"]
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
*/
