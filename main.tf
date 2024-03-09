resource "aws_vpc" "vpcproj" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "sub1" {

  vpc_id = aws_vpc.vpcproj.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = "true"

}

resource "aws_subnet" "sub2" {

  vpc_id = aws_vpc.vpcproj.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = "true"

}

resource "aws_internet_gateway" "ig" {
    vpc_id = aws_vpc.vpcproj.id
  
}
resource "aws_route_table" "rt" {
    
    vpc_id = aws_vpc.vpcproj.id

     route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }

}
resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.sub1.id
    route_table_id = aws_route_table.rt.id
  
}
resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.sub2.id
    route_table_id = aws_route_table.rt.id
  
}

resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.vpcproj.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "s3" {
    bucket = "projhellobuck"
  
}

resource "aws_instance" "ins1" {
    ami = "ami-07d9b9ddc6cd8dd30"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.sub1.id
    vpc_security_group_ids = [aws_security_group.webSg.id]
    user_data = base64encode(file("userdata.sh"))
  
}

resource "aws_instance" "ins2" {
    ami = "ami-07d9b9ddc6cd8dd30"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.sub2.id
    vpc_security_group_ids = [aws_security_group.webSg.id]
    user_data =  base64encode(file("userdata1.sh"))
  
}

resource "aws_alb" "alb" {
    name = "myalb"
    internal = "false"
    load_balancer_type = "application"
    security_groups = [aws_security_group.webSg.id]
    subnets = [aws_subnet.sub1.id,aws_subnet.sub2.id]
  }

  resource "aws_lb_target_group" "tg" {
    name="tg"
    port = 80
    protocol = "HTTP"
    vpc_id = aws_vpc.vpcproj.id
    health_check {
      path = "/"
      port = "traffic-port"
    }
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.ins1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.ins2.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

output "loadbalancerdns" {
  value = aws_alb.alb.dns_name
}
