provider "aws" {
    region = "${var.aws_region}"
}

data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}

resource "aws_instance" "key_cloak" {
    ami           = "${data.aws_ami.ubuntu.id}"
    instance_type = "t3.micro"

    root_block_device {
      volume_type = "gp3"
      volume_size = 8
      delete_on_termination = true
    }
    ebs_block_device {
      device_name = ""
    }

    tags {
        Name = "keycloak instance1"
    }
}
