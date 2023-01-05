# -- root/providers.tf --

locals{
  image_name = "test-nginx"
}

resource "aws_iam_policy" "ecr_policy" {
  name        = "ecr-policy"
  path        = "/"
  description = "Policy for pushing images to ECR"

  policy =  jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "ecr-policy",
              "Effect": "Allow",
              "Action": [
                  "ecr:PutImageTagMutability",
                  "ecr:StartImageScan",
                  "ecr:DescribeImageReplicationStatus",
                  "ecr:ListTagsForResource",
                  "ecr:UploadLayerPart",
                  "ecr:BatchDeleteImage",
                  "ecr:CreatePullThroughCacheRule",
                  "ecr:ListImages",
                  "ecr:BatchGetRepositoryScanningConfiguration",
                  "ecr:DeleteRepository",
                  "ecr:GetRegistryScanningConfiguration",
                  "ecr:CompleteLayerUpload",
                  "ecr:TagResource",
                  "ecr:DescribeRepositories",
                  "ecr:BatchCheckLayerAvailability",
                  "ecr:ReplicateImage",
                  "ecr:GetLifecyclePolicy",
                  "ecr:GetRegistryPolicy",
                  "ecr:PutLifecyclePolicy",
                  "ecr:DescribeImageScanFindings",
                  "ecr:GetLifecyclePolicyPreview",
                  "ecr:CreateRepository",
                  "ecr:DescribeRegistry",
                  "ecr:PutImageScanningConfiguration",
                  "ecr:GetDownloadUrlForLayer",
                  "ecr:DescribePullThroughCacheRules",
                  "ecr:GetAuthorizationToken",
                  "ecr:PutRegistryScanningConfiguration",
                  "ecr:DeletePullThroughCacheRule",
                  "ecr:DeleteLifecyclePolicy",
                  "ecr:PutImage",
                  "ecr:BatchImportUpstreamImage",
                  "ecr:UntagResource",
                  "ecr:BatchGetImage",
                  "ecr:DescribeImages",
                  "ecr:StartLifecyclePolicyPreview",
                  "ecr:InitiateLayerUpload",
                  "ecr:GetRepositoryPolicy",
                  "ecr:PutReplicationConfiguration"
              ],
              "Resource": "*"
          }
      ]
    }
  )
}

resource "aws_iam_role" "assume_role" {
  name = "assume-role"
  assume_role_policy = jsonencode(
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  role       = aws_iam_role.assume_role.name
  policy_arn = aws_iam_policy.ecr_policy.arn
}

resource "aws_iam_instance_profile" "ecr_profile" {
  name = "ecr-profile"
  role = aws_iam_role.assume_role.name
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
  
   ingress {
    description      = "HTTP access"
    from_port        = 8080
    to_port          = 8080
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

resource "aws_ecr_repository" "ecr_repo" {
  name                 = "${local.image_name}"
  image_tag_mutability = "MUTABLE"
  force_delete = true
  
  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_instance" "amazon_linux_node" {
    instance_type = "t2.micro"
    ami = "ami-0b5eea76982371e91"
    tags = {
        Name = "Docker Amazon Linux Instance"
    }
    key_name = "LabKey"
    iam_instance_profile = aws_iam_instance_profile.ecr_profile.name
    user_data = templatefile("${path.module}/userdata.sh", {image_name=local.image_name})
    security_groups = ["${aws_security_group.allow_ssh_http.name}"]
    depends_on = [aws_security_group.allow_ssh_http, aws_ecr_repository.test_nginx_ecr_repo]
}