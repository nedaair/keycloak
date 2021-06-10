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

resource "aws_instance" "keycloak_instance" {
    ami           = "${data.aws_ami.ubuntu.id}"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.keycloak_subnet.id

    root_block_device {
      volume_type = "gp3"
      volume_size = 8
      delete_on_termination = true
    }

    user_data = <<-EOF
		#! /bin/bash
        #install java
        sudo apt-add-repository ppa:webupd8team/java
        sudo apt-get update
        sudo apt-get install oracle-java8-installer

        #install keycloak
        sudo wget https://github.com/keycloak/keycloak/releases/download/13.0.1/keycloak-13.0.1.tar.gz
        sudo tar -zxvf keycloak-13.0.1.tar.gz

	EOF

    tags = {
        "Name" : "keycloak"
    }

    key_name = "megazone"

    associate_public_ip_address = true
}

resource "aws_security_group" "keycloak_security_group" {
    name = "keycloak_security_group"
}

resource "aws_security_group_rule" "keycloak_security_group_rule_ssh" {
    from_port = 22
    protocol = "tcp"
    security_group_id = aws_security_group.keycloak_security_group.id
    to_port = 22
    type = "ingress"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "keycloak_security_group_rule_admin" {
    from_port = 8080
    protocol = "tcp"
    security_group_id = aws_security_group.keycloak_security_group.id
    to_port = 8080
    type = "ingress"
    cidr_blocks = ["0.0.0.0/0"]
}
