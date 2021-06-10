resource "aws_vpc" "keycloak_vpc" {
    cidr_block = var.vpc_cidr
}

resource "aws_subnet" "keycloak_subnet" {
    cidr_block = var.subnet_cidr
    vpc_id = aws_vpc.keycloak_vpc.id
}

resource "aws_internet_gateway" "keycloak_internet_gateway" {
    vpc_id = aws_vpc.keycloak_vpc.id
}

resource "aws_route_table" "keycloak_route_table" {
    vpc_id = aws_vpc.keycloak_vpc.id


}

resource "aws_route_table_association" "keycloak_route_table_association" {
    route_table_id = aws_route_table.keycloak_route_table.id
    subnet_id = aws_subnet.keycloak_subnet.id
}

resource "aws_route" "keycloak_public" {
	route_table_id         = aws_route_table.keycloak_route_table.id
	destination_cidr_block = "0.0.0.0/0"
	gateway_id             = aws_internet_gateway.keycloak_internet_gateway.id
}