#!/bin/bash

# This script sets up a static website on an EC2 instance and then sets up the same site on S3.

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

# Create environment variables for AWS CLI credentials
export AWS_ACCESS_KEY_ID="<Enter AWS Access Key ID>"
export AWS_SECRET_ACCESS_KEY="<Enter AWS Secret Key>"

# Configure AWS CLI with the provided credentials
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"

# Create an environment variable for the S3 bucket name
S3_BUCKET_NAME="aws-ec2-s3-website-josephakayesi"

# Create an S3 bucket
aws s3api create-bucket --bucket $S3_BUCKET_NAME 

# Enable public access for the S3 bucket
aws s3api delete-public-access-block --bucket $S3_BUCKET_NAME   

# Enable website hosting on the S3 bucket
aws s3 website s3://$S3_BUCKET_NAME --index-document index.html --error-document index.html 

# Upload website content to the S3 bucket
aws s3 sync /usr/share/nginx/html/ s3://$S3_BUCKET_NAME 

# Create the S3 bucket policy document
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

# Apply the policy to the S3 bucket
aws s3api put-bucket-policy --bucket $S3_BUCKET_NAME --policy file://policy.json

# Clean up
rm policy.json
