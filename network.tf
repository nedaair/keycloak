resource "aws_vpc" "keycloak_vpc" {
    cidr_block = var.vpc_cidr
}

resource "aws_subnet" "keycloak_public_subnet1" {
    cidr_block = var.public_subnet_cidr
    vpc_id = aws_vpc.keycloak_vpc.id
}

resource "aws_subnet" "keycloak_public_subnet2" {
    cidr_block = var.public_subnet_cidr1
    vpc_id = aws_vpc.keycloak_vpc.id
}

resource "aws_subnet" "keycloak_private_subnet" {
    cidr_block = var.private_subnet_cidr
    vpc_id = aws_vpc.keycloak_vpc.id
}


resource "aws_internet_gateway" "keycloak_internet_gateway" {
    vpc_id = aws_vpc.keycloak_vpc.id
}

resource "aws_route_table" "keycloak_public_route_table" {
    vpc_id = aws_vpc.keycloak_vpc.id
}


resource "aws_route_table_association" "keycloak_public_route_table_association" {
    route_table_id = aws_route_table.keycloak_public_route_table.id
    subnet_id = aws_subnet.keycloak_public_subnet1.id
}

resource "aws_route_table_association" "keycloak_public_route_table_association" {
    route_table_id = aws_route_table.keycloak_public_route_table.id
    subnet_id = aws_subnet.keycloak_public_subnet2.id
}

resource "aws_route" "keycloak_public_route" {
	route_table_id         = aws_route_table.keycloak_public_route_table.id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id             = aws_internet_gateway.keycloak_internet_gateway.id
}

resource "aws_eip" "keycloak_nat_eip" {
  vpc = true
}

resource "aws_nat_gateway" "keycloak_nat_gateway" {
  allocation_id = aws_eip.keycloak_nat_eip.id
  subnet_id = aws_subnet.keycloak_public_subnet1.id
}

resource "aws_route_table" "keycloak_private_route_table" {
    vpc_id = aws_vpc.keycloak_vpc.id
}

resource "aws_route_table_association" "keycloak_private_route_table_association" {
    route_table_id = aws_route_table.keycloak_private_route_table.id
    subnet_id = aws_subnet.keycloak_private_subnet.id
}

resource "aws_route" "keycloak_private_route" {
	route_table_id         = aws_route_table.keycloak_private_route_table.id
	destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.keycloak_nat_gateway.id
}

resource "aws_alb" "keycloak_alb" {
  name = "keycloak-alb"
  internal = false

  subnets         = [
    aws_subnet.keycloak_public_subnet1.id, aws_subnet.keycloak_public_subnet2.id
  ]

  lifecycle { create_before_destroy = true }

}

resource "aws_alb_listener" "keycloak_alb_listner" {
  load_balancer_arn = aws_alb.keycloak_alb.arn
  port = 443
  protocol = "HTTPS"
  default_action {
    type = "forward"
  }
}

resource "aws_alb_target_group" "keycloak_alb_target_group" {
  vpc_id = aws_vpc.keycloak_vpc.id

}