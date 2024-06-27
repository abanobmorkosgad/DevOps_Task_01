variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "availability_zone" {
  default = "us-east-1a"
}

variable "ami" {
  default = "ami-04b70fa74e45c3917"
}

variable "instance_type" {
  default = "t3.large"
}

