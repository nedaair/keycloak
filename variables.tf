variable "aws_region" {
  default = "ap-northeast-2"
  description = "aws region"
}

variable "vpc_cidr" {
  default = "10.29.0.0/16"
  description = "key cloak vpc cidr"
}

variable "subnet_cidr" {
  default = "10.29.0.0/24"
  description = "key cloak subnet"
}

variable "key_name" {
  description = "key name"
}