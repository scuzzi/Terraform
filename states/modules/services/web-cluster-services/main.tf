
/* provider "aws" {

  region = "us-east-2"

}
*/

data "aws_vpc" "default" {
  default = true

}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#Reading the state file outputs - remote state
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-2"

  }
}


/* resource "aws_instance" "example" {
  ami                    = "ami-0fb653ca2d3203ac1"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
                    #!/bin/bash
                    echo "Hello, World" > index.html
                    nohup busybox httpd -f -p ${var.server_port} &
                    EOF
  # Required when using a launch configuration with an autoscaling group.
  lifecycle {
    create_before_destroy = true
  }

  user_data_replace_on_change = true

  tags = {
    Name = "terraform-example"
  }
}
*/

locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]

}


resource "aws_launch_template" "example" {
  name_prefix   = "terraform-example-"
  image_id      = "ami-0fb653ca2d3203ac1"
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.instance.id]

  /* user_data = base64encode(<<-EOF
              #!/bin/bash
              echo "Hello, World" >> index.xhtml
              echo "${data.terraform_remote_state.db.outputs.address}" >> index.xhtml
              echo "${data.terraform_remote_state.db.outputs.port}" >> index.xhtml
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  )
  */

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port


  }))



  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_autoscaling_group" "example" {
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }


  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}

#Security Groups

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-instance"
  #Commented out to make empty - using separate resources instead
  /*
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
*/
}

resource "aws_security_group_rule" "allow_server_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id
  from_port         = var.server_port
  to_port           = var.server_port
  protocol          = local.tcp_protocol
  cidr_blocks       = local.all_ips
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id
  from_port         = 22
  to_port           = 22
  protocol          = local.tcp_protocol
  cidr_blocks       = local.all_ips
}

resource "aws_security_group_rule" "allow_instance_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.instance.id
  from_port         = local.any_port
  to_port           = local.any_port
  protocol          = local.any_protocol
  cidr_blocks       = local.all_ips
}


#Load balancer security groups
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
  #Commented out to make empty - using separate resources instead
  /*
  ingress {
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }

  egress {
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = local.tcp_protocol
    cidr_blocks = local.all_ips
  }
*/
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port         = local.http_port
  to_port           = local.http_port
  protocol          = local.tcp_protocol
  cidr_blocks       = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id
  from_port         = local.any_port
  to_port           = local.any_port
  protocol          = local.any_protocol
  cidr_blocks       = local.all_ips
}



#Creating the load balancer

resource "aws_lb" "example" {
  name               = "${var.cluster_name}-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

#Load Balancer resources

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = local.http_port
  protocol          = "HTTP"

  #default actions
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }

  }
}



#ASG Target group 
resource "aws_lb_target_group" "asg" {
  name     = "${var.cluster_name}-alb"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


#ASG listener rules
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}


terraform {
  backend "s3" {
    bucket         = "terraform-up-and-running-tutorial"
    key            = "web-cluster-services/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true

  }
}