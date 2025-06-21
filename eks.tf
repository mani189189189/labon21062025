provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "test-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "test-subnet" {
  vpc_id     = "aws_vpc.test-vpc.id"
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "demo-subnet" {
  vpc_id     = "aws_vpc.test-vpc.id"
  cidr_block = "10.0.2.0/24"
}

resource "aws_security_group" "test-sg" {
  name   = "test-sg"
  vpc_id = "aws_vpc.test-vpc.id"
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "test-sg"
  }
}
resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_eks_cluster" "eks-example" {
  name     = "eks-example"
  role_arn = aws_iam_role.eks_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.test-subnet.id, aws_subnet.demo-subnet.id]
  }
}

resource "aws_eks_node_group" "my_node_group" {
  cluster_name    = aws_eks_cluster.eks-example.name
  node_group_name = "my-node-group"
  node_role_arn   = aws_iam_role.eks_role.arn
  subnet_ids      = [aws_subnet.test-subnet.id, aws_subnet.demo-subnet.id]

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  remote_access {
    ec2_ssh_key = "manikp"
  }
}

resource "aws_launch_template" "my_launch_template" {
  name_prefix   = "my-launch-template"
  image_id      = "ami-12345678"
  instance_type = "t3.micro"
  key_name      = "mainkp"
}

resource "aws_ecr_repository" "test_ecr_repo" {
  name                 = "my-ecr-repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

output "eks_cluster_arn" {
  value = aws_iam_role.eks_role.arn
}