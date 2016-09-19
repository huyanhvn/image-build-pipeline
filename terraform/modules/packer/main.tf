resource "aws_security_group" "packer-instance" {
  name = "${var.tags["Environment"]}-${var.aws_region}-${var.tags["AppName"]}-packer-instance-sg"
  description = "Allow traffic in from Jenkins build host"
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      security_groups = [ "${var.jenkins_sg_id}" ]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}