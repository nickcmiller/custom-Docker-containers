# -- root/providers.tf --

resource "aws_instance" "ubuntu_node" {
    instance_type = "t2.micro"
    ami = "ami-0574da719dca65348"
    tags = {
        Name = "Docker Ubuntu Instance"
    }
    key_name = "LabKey"
    user_data = file("${path.module}/userdata.sh")
    security_groups = ["${aws_security_group.allow_ssh_http.name}"]
    depends_on = [aws_security_group.allow_ssh_http]
}


resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP inbound traffic"

  ingress {
    description      = "SSH access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    description      = "HTTP access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh_http"
  }
  
  lifecycle{
    create_before_destroy = true
  }
}

resource "aws_ecr_repository" "nginx_ecr" {
  name                 = "nginx-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}