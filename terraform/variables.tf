### AWS creds
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {}

### Common
variable "availability_zones" { type = "list" }
variable "tags" { 
  type = "map" 
  default = {}
}
variable "secrets_s3_bucket" {}
variable "prevent_destroy" {}
variable "ssh_key_name" {}
variable "ssh_ingress" {}

### Jenkins
