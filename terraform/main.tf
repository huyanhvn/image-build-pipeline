# Configure the AWS Provider
provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

module "elb" {
  source = "./modules/elb"
  tags = "${var.tags}"
  ssh_ingress = "${var.ssh_ingress}"
  aws_region = "${var.aws_region}"
  availability_zones = "${var.availability_zones}"
}

# Create one-host Jenkins cluster using Chef cookbook
module "jenkins" {
  source = "./modules/jenkins"
  secrets_s3_bucket = "${var.secrets_s3_bucket}"
  aws_region = "${var.aws_region}"
  tags = "${var.tags}"
  ssh_key_name = "${var.ssh_key_name}"
  ssh_ingress = "${var.ssh_ingress}"
  elb_name = "${module.elb.elb_name}"
  elb_sg_id = "${module.elb.elb_sg_id}"
  availability_zones = "${var.availability_zones}"
}

# Create resources needed for Packer to run
module "packer" {
  source = "./modules/packer"
  aws_region = "${var.aws_region}"
  tags = "${var.tags}"
  jenkins_sg_id = "${module.jenkins.jenkins_sg_id}"
}
