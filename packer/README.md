# Instructions
Automatic gold AMI build with Hashicorp packer + serverspec

## Provision EC2 instance to run `packer`
The EC2 instance needs following policy attached to its instance IAM role:
```
{
    "Version": "2012-10-17",
    "Statement": [
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
                "ec2:DescribeSecurityGroups",
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
            "Resource": "arn:aws:s3:::bb-*-webops-chef/*"
        }
    ]
}
```

## Install `packer`
```
$ curl -vO https://releases.hashicorp.com/packer/0.10.1/packer_0.10.1_linux_amd64.zip
$ sudo unzip packer_0.10.1_linux_amd64.zip -d /usr/bin
```

## Clone pipeline artifacts
Copy contents of [https://github.com/huyanhvn/image-build-pipeline/tree/master/packer] to working directory.

## Pass input params for the build
Input params need to be set in individual `Packerfile`. Set them to respective AWS environments you're building in.

| Param              | Explanation                                     | Example                                   |
| -------------------|:-----------------------------------------------:| -----------------------------------------:|
| ami_name           | AMI snapshot name (to be timestamped by packer) | ubuntu-build               |
| source_ami_id      | Source AMI    | ami-6d1c2007                              |
| aws_region         | Region the AMI is being built in                | us-east-1                                 |
| ami_instance_type  | Instance type for temporary EC2 instance        | t2.micro                                 |
| ami_description    | AMI snapshot description                        | Ubuntu 14.044 (Packer build)        |
| ami_volume_size             | Root volume size (GB)   | 8                              |
| ami_volume_type          | Root volume type (magnetic/ssd)       | gp2                           |
| security_group_id  | SG for temp EC2 instance (*Important*: must allow SSH from packer host) | sg-xxxxxxxx |
| chef_runlist       | Chef runlist to build the AMI                   | recipe[build-cookbook::ubuntu]         |
| secrets_s3_bucket     | S3 bucket where validator key is (*Important*: packer host must be able to access this bucket) | your-secrets-bucket |
| ssh_username | Default user to SSH in | ubuntu |
| ssh_home_dir | Home directory of SSH user | /home/ubuntu |

## Build
From working directory, issue command (example below for CentOS 7):
```
$ packer build -machine-readable Packerfile.centos7 | tee packer_output.log
$ bash share-ami.sh ./packer_output.log
```
Note: list of AMIs for share-ami.sh can be overriden via environment variable $AMIS. See script for usage.

## serverspec tests
As part of the build template, Packer would attempt to run a bunch of serverspec tests to validate the image. Set them using the recipe serverspec/localhost/sample_spec.rb

## Output
Successful AMI is created in AWS account under "EC2" --> "AMIs". AMIs are copied to all regions specified in "ami_regions" inside Packerfile. AMIs are also shared with all accounts specified in share-ami.sh
