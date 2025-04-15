provider "aws" {
  region  = "ap-northeast-1"
  profile = "katsukiniwa-admin"
}

variable "env" {
  default = {
    env_name     = "til_golang"
    vpc_cidr     = "10.1.0.0/16"
    sb_az1a      = "ap-northeast-1a"
    sb_az1a_cidr = "10.1.1.0/24"
    sb_az1c      = "ap-northeast-1c"
    sb_az1c_cidr = "10.1.2.0/24"
  }
}

### VPC
#tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "vpc" {
  cidr_block = var.env.vpc_cidr
  tags = {
    Name = "${var.env.env_name}_vpc"
  }
}

### Subnet
resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.env.sb_az1a
  cidr_block        = var.env.sb_az1a_cidr
  tags = {
    Name = "${var.env.env_name}_public_1a"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.env.sb_az1c
  cidr_block        = var.env.sb_az1c_cidr
  tags = {
    Name = "${var.env.env_name}_public_1c"
  }
}

### InternetGateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.env.env_name}_igw"
  }
}

### RouteTable
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env.env_name}_public_route_table"
  }
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

### SecurityGroup
resource "aws_security_group" "ecs" {
  name        = "${var.env.env_name}_ecs_sg"
  description = "security group for ECS tasks"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_security_group_rule" "ecs_ingress" {
  type      = "ingress"
  from_port = 8080
  to_port   = 8080
  protocol  = "tcp"
  #tfsec:ignore:aws-ec2-no-public-ingress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
  description       = "Allow all traffic in"
}

resource "aws_security_group_rule" "ecs_egress" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs.id
  description       = "Allow all traffic out"
}

### ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.env.env_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

### ECS TaskDefinition
resource "aws_ecs_task_definition" "til_golang" {
  family                   = "${var.env.env_name}_app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  track_latest             = false

  container_definitions = jsonencode([
    {
      name      = "til-golang"
      image     = "175465510121.dkr.ecr.ap-northeast-1.amazonaws.com/til-golang:latest"
      cpu       = 128
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])

  lifecycle {
    ignore_changes = [
      container_definitions
    ]
  }

  tags = {
    Environment = "Prod"
    Service     = "til-golang"
  }
}

### ECS Service
resource "aws_ecs_service" "til_golang" {
  name            = "${var.env.env_name}_app"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.til_golang.arn
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 0
    weight            = 0
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    base              = 0
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "til-golang"
    container_port   = 8080
  }
}
