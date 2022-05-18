provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_launch_configuration" "example" {
  image_id                 = "ami-0672b175139a0f8f4"
  instance_type          = "t2.micro"
  security_groups        = [ "${aws_security_group.instance.id}" ]

  user_data = <<-EOF
              #!/bin/bash
              echo "hello, world" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF
  
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port   = "${var.server_port}"
    protocol    = "tcp"
    to_port     = "${var.server_port}"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones   = "${data.aws_availability_zones.all.names}"
 
  load_balancers    = ["${aws_elb.example.name}"]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "terraform_asg_example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "example" {
  name               = "terraform-asg-example"
  availability_zones = "${data.aws_availability_zones.all.names}"
  # availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  security_groups    = ["${aws_security_group.elb.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout            = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"

  }   
}

resource "aws_security_group" "elb" {
  name = "terraform-example-elb"

  ingress  {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  } 

  egress  {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  } 
}

data "aws_availability_zones" "all" {
  
}

variable "server_port" {
  description = "use for http requests"
  default     = 8080
}

output "elb_dns_name" {
  value = "${aws_elb.example.dns_name}"
}


