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
        sudo apt-get update
        sudo apt-get install openjdk-8-jdk -y

        #install keycloak
        sudo wget https://github.com/keycloak/keycloak/releases/download/13.0.1/keycloak-13.0.1.tar.gz -P /root
        sudo tar -zxvf /root/keycloak-13.0.1.tar.gz -C /root
        sudo sed -i -e '/127.0.0.1/ s/\(localhost\)/'$(hostname)' \1/' /etc/hosts
        sudo /root/keycloak-13.0.1/bin/add-user-keycloak.sh -r master -u admin -p 123qwe
        sudo /root/keycloak-13.0.1/bin/standalone.sh -b 0.0.0.0 &
	EOF

    tags = {
        "Name" : "keycloak"
    }

    key_name = "megazone"
    vpc_security_group_ids = [ aws_security_group.keycloak_security_group.id]

    associate_public_ip_address = true
}

resource "aws_security_group" "keycloak_security_group" {
    name = "keycloak_security_group"
    vpc_id = aws_vpc.keycloak_vpc.id
}


resource "aws_security_group_rule" "keycloak_security_group_rule_admin" {
    from_port = 9990
    protocol = "tcp"
    security_group_id = aws_security_group.keycloak_security_group.id
    to_port = 9990
    type = "ingress"
    cidr_blocks      = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "keycloak_security_group_rule_ssh" {
    from_port = 22
    protocol = "tcp"
    security_group_id = aws_security_group.keycloak_security_group.id
    to_port = 22
    type = "ingress"
    cidr_blocks      = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "keycloak_security_group_rule_egress" {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_group_id = aws_security_group.keycloak_security_group.id
    type = "egress"
    cidr_blocks      = ["0.0.0.0/0"]
}

output "keycloak_admin_address" {
    value = aws_instance.keycloak_instance.public_ip
}
