provider "aws" {
    region = "${var.aws_region}"
}

resource "aws_instance" "keycloak_instance" {
    ami           = "${data.aws_ami.ubuntu.id}"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.keycloak_private_subnet.id
    iam_instance_profile        = aws_iam_instance_profile.keycloak_instance_profile.name

    root_block_device {
      volume_type = "gp3"
      volume_size = 8
      delete_on_termination = true
    }

    user_data = <<-EOF
		#! /bin/bash

        #hosts file modify
        sudo sed -i -e '/127.0.0.1/ s/\(localhost\)/'$(hostname)' \1/' /etc/hosts

        #install java
        sudo apt-get update
        sudo apt-get install openjdk-8-jdk -y

        #install ssm agent
        sudo snap install amazon-ssm-agent --classic

        #install keycloak
        sudo wget https://github.com/keycloak/keycloak/releases/download/13.0.1/keycloak-13.0.1.tar.gz -P /root
        sudo tar -zxvf /root/keycloak-13.0.1.tar.gz -C /root
        sudo /root/keycloak-13.0.1/bin/add-user-keycloak.sh -r master -u admin -p "${var.keyclaok_password}"
        sudo /root/keycloak-13.0.1/bin/standalone.sh -b 127.0.0.1 &


	EOF

    tags = {
        "Name" : "keycloak"
    }

    key_name = var.key_name
    vpc_security_group_ids = [ aws_security_group.keycloak_security_group.id]
}

resource "aws_security_group" "keycloak_alb_security_group" {
    name = "keycloak_alb_security_group"
    vpc_id = aws_vpc.keycloak_vpc.id
}

resource "aws_security_group_rule" "keycloak_alb_security_group_rule" {
    from_port = 443
    protocol = "tcp"
    security_group_id = aws_security_group.keycloak_alb_security_group.id
    to_port = 443
    type = "ingress"
    cidr_blocks      = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "keycloak_alb_security_group_rule_egress" {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_group_id = aws_security_group.keycloak_alb_security_group.id
    type = "egress"
    cidr_blocks      = ["0.0.0.0/0"]
}

resource "aws_security_group" "keycloak_security_group" {
    name = "keycloak_security_group"
    vpc_id = aws_vpc.keycloak_vpc.id
}


resource "aws_security_group_rule" "keycloak_security_group_rule_admin" {
    from_port = 8080
    protocol = "tcp"
    security_group_id = aws_security_group.keycloak_security_group.id
    to_port = 8080
    type = "ingress"
    source_security_group_id = aws_security_group.keycloak_alb_security_group.id
}


resource "aws_security_group_rule" "keycloak_security_group_rule_egress" {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_group_id = aws_security_group.keycloak_security_group.id
    type = "egress"
    cidr_blocks      = ["0.0.0.0/0"]
}

resource "aws_iam_role" "keycloak_role" {
    name               = "keycloak_role"
    path               = "/"
    assume_role_policy = <<POLICY
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_instance_profile" "keycloak_instance_profile" {
  name = "keycloak_instance_profile"
  role = aws_iam_role.keycloak_role.name
}

resource "aws_iam_policy_attachment" "AmazonSSMManagedInstanceCore" {
  name       = "AmazonSSMManagedInstanceCore"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  roles      = [ "AmazonSSMRoleForInstancesQuickSetup", "${aws_iam_role.keycloak_role.name}" ]
}