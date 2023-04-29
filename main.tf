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
  region  = "eu-central-1"
}

provider "aws" {
  profile = "terraform"
  alias   = "secondary"
  region  = "eu-west-3"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

data "aws_ami" "ubuntu_secondary" {
  provider = aws.secondary
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "instance_1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
}

resource "aws_instance" "instance_2" {
  
  depends_on             = [aws_instance.instance_1]
  ami                    = data.aws_ami.ubuntu_secondary.id
  instance_type          = "t2.micro"
  provider = aws.secondary
}


