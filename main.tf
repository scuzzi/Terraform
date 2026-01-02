
provider "aws" {

region = "us-east-2"

}

data "aws_vpc" "default" {
default = true

}

data "aws_subnets" "default" {
filter {
name = "vpc-id"
values = [data.aws_vpc.default.id]
}
}


 variable "server_port" {
        description = "The port the server will use for HTTP requests"
        type = number
        default = 8080
}


resource "aws_instance" "example" {
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

#name_prefix   = "terraform-example-"
#  image_id      = "ami-0fb653ca2d3203ac1"
# instance_type = "t2.micro"
# 
 #  vpc_security_group_ids = [aws_security_group.instance.id]
# 
 #  user_data = base64encode(<<-EOF
 #              #!/bin/bash
 #              echo "Hello, World" > index.html
 #              EOF
 #  )
 # 
 # lifecycle {
  #  create_before_destroy = true
 # }
#}





resource "aws_autoscaling_group" "example"{
    vpc_zone_identifier = data.aws_subnets.default.ids

    min_size = 2
    max_size = 10

    launch_template {
      id      = aws_launch_template.example.id
      version = "$Latest"
    }

    
    
    tag {
        key                 = "Name"
        value               = "terraform-asg-example"
        propagate_at_launch = true
    }
}



resource "aws_security_group" "instance" {
        name = "terraform-example-instance"

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
}

output "public_ip" {
value = aws_instance.example.public_ip
description = "The public IP address of the web server"
}