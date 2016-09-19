data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/ebs/ubuntu-trusty-14.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["paravirtual"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_iam_role" "jenkins" {
  name = "${var.tags["Environment"]}-${var.aws_region}-${var.tags["AppName"]}-jenkins-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
} 
EOF
}

resource "aws_iam_role_policy" "jenkins" {
  name = "${var.tags["Environment"]}-${var.aws_region}-${var.tags["AppName"]}-jenkins-policy"
  role = "${aws_iam_role.jenkins.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement" : [
    {
      "Effect": "Allow",
      "Action": [
          "ec2:AttachVolume",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:CreateKeypair",
          "ec2:DeleteKeypair",
          "ec2:DescribeSubnets",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateImage",
          "ec2:CopyImage",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:StopInstances",
          "ec2:DescribeVolumes",
          "ec2:DetachVolume",
          "ec2:DescribeInstances",
          "ec2:CreateSnapshot",
          "ec2:DeleteSnapshot",
          "ec2:DescribeSnapshots",
          "ec2:DescribeImages",
          "ec2:RegisterImage",
          "ec2:DeregisterImage",
          "ec2:CreateTags",
          "ec2:ModifyImageAttribute"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Resource": "arn:aws:s3:::${var.secrets_s3_bucket}/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:List*"
      ],
      "Resource": "*"
    },
    {
      "Resource": "arn:aws:logs:*:*:log-group:*",
      "Action": [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
      ],
      "Effect": "Allow"
    }
  ]
} 
EOF
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.tags["Environment"]}-${var.aws_region}-${var.tags["AppName"]}-jenkins-profile"
  roles = ["${aws_iam_role.jenkins.name}"]
}

resource "aws_security_group" "jenkins" {
  name = "${var.tags["Environment"]}-${var.aws_region}-${var.tags["AppName"]}-jenkins-sg"
  description = "Allow traffic in"
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = [ "${var.ssh_ingress}" ]
  }
  ingress {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      security_groups = [ "${var.elb_sg_id}" ]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "jenkins" {
  ### Use image_id = "${data.aws_ami.ubuntu.id}" for dynamic ami-id
  image_id = "ami-2d39803a"    ## Ubuntu, free-tier eligible
  instance_type = "t2.micro"   ## free-tier eligible
  iam_instance_profile = "${aws_iam_instance_profile.jenkins.name}" 
  key_name = "${var.ssh_key_name}"
  security_groups = [ "${aws_security_group.jenkins.name}" ]
  lifecycle {
    create_before_destroy = true
  }
  user_data = "${file("modules/jenkins/userdata.sh")}"
}

resource "aws_autoscaling_group" "jenkins" {
  name = "${var.tags["Environment"]}-${var.aws_region}-${var.tags["AppName"]}-jenkins-sg"
  availability_zones = "${var.availability_zones}"
  max_size = 1
  min_size = 1
  health_check_grace_period = 300
  health_check_type = "EC2"
  desired_capacity = 1
  force_delete = false
  launch_configuration = "${aws_launch_configuration.jenkins.name}"
  load_balancers = [ "${var.elb_name}" ]
  tag {
    key = "CostCenter"
    value = "${var.tags["CostCenter"]}"
    propagate_at_launch = true
  }
  tag {
    key = "Name"
    value = "${var.tags["Environment"]}-${var.aws_region}-${var.tags["AppName"]}-jenkins"
    propagate_at_launch = true
  }
}

#### Outputs
output "jenkins_asg_id" {
  value = "${aws_autoscaling_group.jenkins.id}"
}

output "jenkins_sg_id" {
  value = "${aws_security_group.jenkins.id}"
}