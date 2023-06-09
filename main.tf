terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
    profile = "terraform"
    region = "eu-central-1"
}

data "http" "my_ip" {
  url = "https://api.ipify.org"
}

locals {
    my_ip = format("%s/%s",data.http.my_ip.response_body,32)
}

resource "aws_instance" "instance" {
    ami = "ami-0ec7f9846da6b0f61"
    instance_type = "t2.micro"
    key_name      = aws_key_pair.kp.key_name
    vpc_security_group_ids = [aws_security_group.sg.id]

   user_data = <<-EOF
                #!/bin/bash
                apt-get update
                apt-get install -y nginx
                systemctl start nginx
                systemctl enable nginx
                echo "Checking for nginx health"
                until curl --silent --fail http://localhost:80; do
                    echo "Waiting for nginx to be up and healthy"
                    sleep 1
                done
                echo "Nginx is up and healthy"
                EOF
}

resource "aws_key_pair" "kp" {
  key_name   = "my-key-pair"
  public_key = file("terraform.pub")
}

resource "aws_security_group" "sg" {
    name = "app_sg"
    
    ingress {
        description = "ssh"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [local.my_ip]
    }

    ingress {
        description = "ssh"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        description = "http"
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
}

output "ssh_connection" {
  value =  format("ssh -i ~/.ssh/terraform ubuntu@%s",aws_instance.instance.public_ip)
}

output "http_connection" {
  value =  format("http://%s",aws_instance.instance.public_ip)
}

