variable "aws_region" {}
variable "tags" { 
  type = "map"
  default = {}
}
variable "ssh_ingress" {}
variable "availability_zones" { type = "list" }