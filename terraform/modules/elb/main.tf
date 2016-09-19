resource "aws_security_group" "elb" {
  name = "${var.tags["Environment"]}-${var.aws_region}-${var.tags["AppName"]}-jenkins-elb-sg"
  description = "Allow traffic in to ELB"
  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = [ "${var.ssh_ingress}" ]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "jenkins" {
  name = "${var.tags["Environment"]}-${var.aws_region}-${var.tags["AppName"]}-jenkins-elb"
  availability_zones = "${var.availability_zones}"
  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:8080/"
    interval = 30
  }
  security_groups = [ "${aws_security_group.elb.id}" ]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  tags {
    "Name" = "${var.tags["Environment"]}-${var.aws_region}-${var.tags["AppName"]}-jenkins-elb"
    "CostCenter" = "${var.tags["CostCenter"]}"
    "Environment" = "${var.tags["Environment"]}"
    "CreatedBy" = "${var.tags["CreatedBy"]}"
    "AppName" = "${var.tags["AppName"]}"
  }
}

# Outputs
output "elb_sg_id" {
  value = "${aws_security_group.elb.id}"
}
output "elb_name" {
  value = "${aws_elb.jenkins.name}"
}