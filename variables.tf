variable "aws_region" {
  default = "ap-northeast-2"
  description = "aws region"
}

variable "vpc_cidr" {
  default = "10.29.0.0/16"
  description = "key cloak vpc cidr"
}

variable "keycloak_domain" {
  description = "keycloak domain : keycloak.xxxx.com"
}

variable "route53_domain" {
  description = "domain : xxxx.com"
}

variable "public_subnet_cidr" {
  default = "10.29.0.0/24"
  description = "key cloak public subnet"
}

variable "public_subnet_cidr1" {
  default = "10.29.1.0/24"
  description = "key cloak public subnet"
}

variable "private_subnet_cidr" {
  default = "10.29.2.0/24"
  description = "key cloak private subnet"
}

variable "key_name" {
  description = "key name"
}

variable "keyclaok_password" {
  description = "keycloak password"
}