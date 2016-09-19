# jenkins-wrapper

This cookbook is used as part of image-build-pipeline to set up Jenkins. The following items will be set up:
* A Jenkins master node
* Jenkins github pull request builder plugin + dependencies
* A global credential to access Github via token
* Hashicorp Packer executable
* A sample job to build an image using Packer

Custom values can be set in ```attributes/default.rb``` file. Execute cookbook with ```chef-client -r "recipe[jenkins-wrapper::default]"```


