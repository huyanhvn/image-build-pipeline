variable "secrets_s3_bucket" {}
variable "aws_region" {}
variable "tags" { 
  type = "map"
  default = {}
}
variable "ssh_key_name" {}
variable "ssh_ingress" {}
variable "elb_name" {}
variable "elb_sg_id" {}
variable "availability_zones" { type = "list" }