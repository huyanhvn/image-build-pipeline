# image-build-pipeline

A simple image CI/CD pipeline using combination of Github + Jenkins + Hashicorp Packer + Chef + serverspec. Resources are built using Hashicorp Terraform targetting AWS.

Set up Jenkins
--------------
Clone folder ```terraform``` of this repo and set up appropriate vars in ```terraform.tfvars```. Specific variable explanations are below:

| Param              | Explanation                                     |
| -------------------|:-----------------------------------------------:|
| aws_secret_key | Cred of power user that can create all resources Terraform needs |
| aws_access_key | Cred of power user that can create all resources Terraform needs |
| prevent_destroy    | Allow Terraform to delete resources (true|false) |
| secrets_s3_bucket     | S3 bucket that contains Chef's validation key, client.rb and github_token file (encrypted with AWS KMS S3 master key)
| ssh_key_name         | Default SSH user for the base image |
| ssh_ingress  | SSH CIDR range allowed to SSH into EC2 instance and access Jenkins URL |

The secrets_s3_bucket and Chef validator key are needed to be set in ```terraform/modules/jenkins/userdata.sh``` as well.

Execute following to set up:
``` 
$ cd terraform
$ terraform get
$ terraform plan
$ terraform apply
```

If Terraform ran successfully, the following resources would be created:
* An AutoScalingGroup for Jenkins master
* Resources associated with master instance: Security Group, IAM Role, IAM Instance Profile
* An ELB in front of the AutoScalingGroup to redirect HTTP/80 to HTTP/8080

If jenkins-wrapper cookbook ran successfully, the following would be set up:
* A Jenkins master node
* Jenkins github pull request builder plugin + dependencies
* A global credential to access Github via token
* Hashicorp Packer executable
* A sample job to build an image using Packer

Access Jenkins
--------------
If Terraform ran successfully, you could execute ```terraform show``` to see the DNS of the ELB, the access Jenkins via ```http://<ELB DNS name>```

One-Time Jenkins Tasks Upon Setup
---------------------------------
As of currently, Jenkins 1.6 needs these tasks to be performed manually after first time it is setup by the Chef cookbook:
* Go to 'Manage Jenkins' -> 'Configure System' and click 'Save' then click 'Apply'. This is due to error ```java.io.IOException: {"message":"Validation Failed","errors":[{"resource":"Status","code":"custom","field":"target_url","message":"target_url must use http(s) scheme"}]``` while running Github SCM jobs the first time.

Packer build job
----------------
A sample Jenkins job that uses Github Pull Request Builder plugin to run automated Packer builds is created by default from jenkins-wrapper cookbook. Customize the job to your values (or overwrites it using cookbook attributes).

Additional setup is needed to make sure Packer runs correctly. See them [https://github.com/huyanhvn/image-build-pipeline/packer]

Expected end results
--------------------
If the pipeline worked correctly, the new AMI would be built using Chef cookbook ```ubuntu-build```, tested using serverspec, copied to other AWS regions, and shared with other AWS accounts.


