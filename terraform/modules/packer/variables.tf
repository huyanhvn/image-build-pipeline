variable "aws_region" {}
variable "tags" { 
  type = "map"
  default = {}
}
variable "jenkins_sg_id" {}