resource "aws_vpc" "keycloak_vpc" {
    cidr_block = var.vpc_cidr

    tags = {
      Name = "keycloak_vpc"
    }
}

resource "aws_subnet" "keycloak_public_subnet1" {
    cidr_block = var.public_subnet_cidr
    vpc_id = aws_vpc.keycloak_vpc.id

    availability_zone = "${data.aws_availability_zones.available.names[0]}"
}

resource "aws_subnet" "keycloak_public_subnet2" {
    cidr_block = var.public_subnet_cidr1
    vpc_id = aws_vpc.keycloak_vpc.id

      availability_zone = "${data.aws_availability_zones.available.names[1]}"
}

resource "aws_subnet" "keycloak_private_subnet" {
    cidr_block = var.private_subnet_cidr
    vpc_id = aws_vpc.keycloak_vpc.id

    availability_zone = "${data.aws_availability_zones.available.names[0]}"
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

resource "aws_route_table_association" "keycloak_public_route_table_association1" {
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

resource "aws_acm_certificate" "keycloak_certificate" {
  domain_name       = var.keycloak_domain
  validation_method = "DNS"
}

resource "aws_route53_record" "keycloak_domain_record" {
  zone_id = data.aws_route53_zone.domain.zone_id
  name    = var.keycloak_domain
  type    = "A"

  alias {
    name                   = aws_alb.keycloak_alb.dns_name
    zone_id                = aws_alb.keycloak_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "domain" {
  for_each = {
    for dvo in aws_acm_certificate.keycloak_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.domain.zone_id
}

resource "aws_acm_certificate_validation" "keycloak_acm_validation" {
  certificate_arn         = aws_acm_certificate.keycloak_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.domain : record.fqdn]
}

resource "aws_alb" "keycloak_alb" {
  name = "keycloak-alb"
  internal = false

  security_groups = [aws_security_group.keycloak_alb_security_group.id]
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
    target_group_arn = "${aws_alb_target_group.keycloak_alb_target_group.arn}"
    type = "forward"
  }

  certificate_arn = aws_acm_certificate.keycloak_certificate.arn
}


resource "aws_alb_target_group" "keycloak_alb_target_group" {
  vpc_id = aws_vpc.keycloak_vpc.id

  port = 8080
  protocol = "HTTP"

  target_type = "instance"

}

resource "aws_lb_target_group_attachment" "keycloak_alb_target_group_attachment" {
  target_group_arn = aws_alb_target_group.keycloak_alb_target_group.arn
  target_id        = aws_instance.keycloak_instance.id
  port             = 8080
}