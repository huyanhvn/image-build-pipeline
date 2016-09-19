# This script assumes running as 'root'

# Update all packages
# apt-get update -y

# Install awscli
curl -v https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
python /tmp/get-pip.py
pip install awscli

# Install ec2-metadata util
curl -v https://s3.amazonaws.com/ec2metadata/ec2-metadata -o /usr/bin/ec2-metadata
chmod 755 /usr/bin/ec2-metadata

# Install serverspec
yum install -y ruby
/usr/bin/gem install serverspec
