provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_instance" "example" {
  ami           = "ami-0672b175139a0f8f4"
  instance_type = "t2.micro"
  vpc_security_group_ids = [ "${aws_security_group.instance.id}" ]

  user_data = <<-EOF
              #!/bin/bash
              echo "hello, world" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  
  tags      = {
    Name = "terraform_example"
  }

}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = 8080
    protocol = "tcp"
    to_port = 8080
    cidr_blocks = ["0.0.0.0/0"]
  } 
}

