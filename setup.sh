#!/bin/bash

# This is a bash script that setups a static website on EC2 and then sets up the same site on S3

################################
#                              #
#     Update and Install       #
#                              #
################################

# Login as root 
sudo su -

# Update all installed packages
yum update -y

# Install Nginx
yum install nginx -y

# Install Git
yum install git -y

################################
#                              #
#  Setup for EC2 Webserver     #
#                              #
################################

# Remove the existing html directory and its contents
rm -rf /usr/share/nginx/html

# Clone the repository to the html directory
git clone https://github.com/josephakayesi/assignment_files /usr/share/nginx/html 

# Enable Nginx to start on boot
systemctl enable nginx

# Start Nginx service
service nginx start

################################
#                              #
#     Setup for S3 Website     #
#                              #
################################

# Create environment variable for AWS cli credentials
AWS_ACCESS_KEY_ID="<Enter AWS Access Key ID>"
AWS_ACCESS_KEY_SECRET="<Enter AWS Secret Key>"

aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" && aws configure set aws_secret_access_key "$AWS_ACCESS_KEY_SECRET"

# Create environment variable for S3 bucket name
S3_BUCKET_NAME="<Enter bucket name>"

# Create S3 bucket
aws s3api create-bucket \
--bucket $S3_BUCKET_NAME 

# Enable public access
aws s3api delete-public-access-block \
--bucket $S3_BUCKET_NAME   

# Enable website hosting on your bucket
aws s3 website s3://$S3_BUCKET_NAME \
--index-document index.html \
--error-document index.html 

# Uplood website content to S3
aws s3 sync /usr/share/nginx/html/ s3://$S3_BUCKET_NAME 

# echo policy document into policy json file
echo '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::'$S3_BUCKET_NAME'/*"
        }
    ]
}' > policy.json

# apply policy to bucket
aws s3api put-bucket-policy \
--bucket $S3_BUCKET_NAME \
--policy file://policy.json 

# Clean up
rm policy.json