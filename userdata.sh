#!/bin/bash

#install Docker
sudo yum update -y
sudo yum -y install docker 

#allow the ec2-user to run Docker commands without being root
sudo usermod -a -G docker ec2-user
id ec2-user

#make the directory for Dockerfile and navigate to it
mkdir ${image_name}-file
cd ${image_name}-file

#create the Dockerfile
cat << EOF >> Dockerfile 
FROM nginx:latest

#Create a file that tells you the create date of the container
RUN echo "Container created on $(date +'%A, %m/%d/%Y')" > createdate.txt

#Modify the index.html to also tell you the create date of the container
RUN echo "<html> <h1>Welcome to the Container!</h1><p> Created on $(date +'%A, %m/%d/%Y') </p></html>" > /usr/share/nginx/html/index.html
EOF

#Build Docker Nginx container
docker build -t ${image_name}:v1 . #--build-arg now=$(date +'%A, %m/%d/%Y')

#Run Container
docker run -it --rm -d -p 8080:80 --name ${image_name} ${image_name}:v1

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 235447109042.dkr.ecr.us-east-1.amazonaws.com

docker tag ${image_name}:v1 235447109042.dkr.ecr.us-east-1.amazonaws.com/${image_name}:v1

docker push 235447109042.dkr.ecr.us-east-1.amazonaws.com/${image_name}:v1