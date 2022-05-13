provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_instance" "example" {
  ami           = "ami-0672b175139a0f8f4"
  instance_type = "t2.micro"
}