# AWS学習用
# provider
#provider "aws" {
    #access_key = "access_key"
    #secret_key = "secret_key"
    #region = "ap-northeast-1"
#}

# VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "aws-study-vpc"
  }
}

# Subnet
resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-1a"
    tags = {
    Name = "aws-study-public-subnet"
  }
}

resource "aws_subnet" "private_0" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.0.65.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1a"
    tags = {
    Name = "aws-study-private_0"
  }  
}

resource "aws_subnet" "private_1" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "10.0.66.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "ap-northeast-1c"
    tags = {
    Name = "aws-study-private_1"
  }  
}

resource "aws_db_subnet_group" "rds" {
  name       = "aws-study-rds"
  subnet_ids = ["${aws_subnet.private_0.id}", "${aws_subnet.private_1.id}"]
}

# InternetGateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
    tags = {
    Name = "aws-study-gw"
  }  
}

# RouteTable
  ## public 
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"
    tags = {
    Name = "aws-study-routetable-public"
  }  
}
resource "aws_route" "public" {
  route_table_id         = "${aws_route_table.public.id}"
  gateway_id             = "${aws_internet_gateway.gw.id}"
  destination_cidr_block = "0.0.0.0/0"  
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"  
}

  ## private
   ###private_0
resource "aws_route_table" "private_0" {
  vpc_id = "${aws_vpc.vpc.id}"  
}
resource "aws_route_table_association" "private_0" {
  subnet_id      = "${aws_subnet.private_0.id}"
  route_table_id = "${aws_route_table.private_0.id}" 
}
   ###private_1
resource "aws_route_table" "private_1" {
  vpc_id = "${aws_vpc.vpc.id}"  
}
resource "aws_route_table_association" "private_1" {
  subnet_id      = "${aws_subnet.private_1.id}"
  route_table_id = "${aws_route_table.private_1.id}" 
}

# SecurityGroup
  ## EC2 SecurityGroup
resource "aws_security_group" "ec2" {
  vpc_id = "${aws_vpc.vpc.id}"
    tags = {
    Name = "aws-study-securityGroup-ec2"
  }
}
resource "aws_security_group_rule" "ingress_http" {
  type              = "ingress"
  from_port         = "80"
  to_port           = "80"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ec2.id}"
}
resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = "22"
  to_port           = "22"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ec2.id}"
}
resource "aws_security_group_rule" "ingress_local" {
  type              = "ingress"
  from_port         = "3000"
  to_port           = "3000"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ec2.id}"
}
resource "aws_security_group_rule" "egress_ec2-all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ec2.id}"
}

  ## RDS SecurityGroup
resource "aws_security_group" "rds" {
  vpc_id = "${aws_vpc.vpc.id}"
    tags = {
    Name = "aws-study-securityGroup-rds"
  }
}
resource "aws_security_group_rule" "ingress_mysql" {
  type              = "ingress"
  from_port         = "3306"
  to_port           = "3306"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.rds.id}"
}
resource "aws_security_group_rule" "egress_rds-all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.rds.id}"
}
# EC2
resource "aws_instance" "EC2" {
  ami           = "ami-0af1df87db7b650f4"
  instance_type = "t2.micro"
  subnet_id               = "${aws_subnet.public.id}"
  disable_api_termination = false
  instance_initiated_shutdown_behavior = "stop"
  key_name                = "keyname"
  monitoring              = false
  vpc_security_group_ids  = ["${aws_security_group.ec2.id}"]
  associate_public_ip_address = true
    tags = {
    Name = "aws-study-ec2"
  }
}
#resource "aws_network_interface_attachment" "EC2" {
  #instance_id          = "${aws_instance.EC2.id}"
  #network_interface_id = "${aws_network_interface.EC2.id}"
  #device_index         = 0
#}

# RDS
resource "aws_db_parameter_group" "rds" {
  name   = "rds"
  family = "mysql8.0"

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}
resource "aws_db_instance" "dbinstance" {
  identifier                 = "aws-study-db"
  engine                     = "mysql"
  engine_version             = "8.0.16"
  instance_class             = "db.t2.micro"
  allocated_storage          = 20
  storage_type               = "gp2"
  storage_encrypted          = false
  #kms_key_id                 = "${aws_kms_key.example.arn}"
  username                   = "root"
  password                   = "password"
  multi_az                   = false
  publicly_accessible        = false
  backup_window              = "15:00-16:00"
  backup_retention_period    = 1
  maintenance_window         = "sun:18:00-sun:19:00"
  auto_minor_version_upgrade = true
  deletion_protection        = false
  skip_final_snapshot        = false
  port                       = 3306
  apply_immediately          = false
  vpc_security_group_ids     = ["${aws_security_group.rds.id}"]
  #parameter_group_name       = "${aws_db_parameter_group.example.name}"
  #option_group_name          = "${aws_db_option_group.example.name}"
  db_subnet_group_name       = "${aws_db_subnet_group.rds.id}"
}

# ELB

resource "aws_lb" "aws-study-elb" {
  name                       = "aws-study-elb"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false

  subnets = [
    "${aws_subnet.public.id}",
    "${aws_subnet.private_1.id}"
  ]

  security_groups = [
    "${aws_security_group.ec2.id}"
  ]
}
resource "aws_lb_target_group" "elb" {
  name                 = "aws-study-elb-target-group"
  vpc_id               = "${aws_vpc.vpc.id}"
  #target_type          = "${aws_instance.EC2.id}"
  port                 = 80
  protocol             = "HTTP"
  #deregistration_delay = 300

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }
}
resource "aws_lb_listener" "elb" {
  load_balancer_arn = "${aws_lb.aws-study-elb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.elb.arn}"
    type             = "forward"
    }
  }