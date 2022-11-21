#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_iam_role" "dev-cluster" {
  name = "terraform-eks-dev-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "dev-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.dev-cluster.name
}

resource "aws_iam_role_policy_attachment" "dev-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.dev-cluster.name
}

resource "aws_security_group" "dev-cluster-sg" {
  name        = "terraform-eks-dev-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.development.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "dev-eks-cluster-sg",
    OWNER    = "SURESH",
    FUNCTION = "EKS-DEV",
    PRODUCT  = "EKS-DEV",
    TEAM     = "DEVOPS",
  }
}

resource "aws_security_group_rule" "dev-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.dev-cluster-sg.id
  source_security_group_id = aws_security_group.dev-node.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "dev-cluster-ingress-it-vpc" {
  description              = "Allow access to API Server with VPN"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.dev-cluster-sg.id
  cidr_blocks              = [var.itvpc_cidr_block]
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group" "dev-rds-sg" {
  name        = "terraform-dev-rds-private"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.development.id

  tags = {
    Name     = "dev-shared-rds",
    OWNER    = "SURESH",
    FUNCTION = "EKS-DEV",
    PRODUCT  = "EKS-DEV",
    TEAM     = "DEVOPS",
  }
}

resource "aws_security_group_rule" "dev-rds-ingress-dev-vpc" {
  description              = "Allow Dev VPC to communicate with MYSQL/Aurora"
  from_port                = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.dev-rds-sg.id
  cidr_blocks              = [var.vpc_cidr_block]
  to_port                  = 3306
  type                     = "ingress"
}

resource "aws_security_group_rule" "dev-rds-ingress-it-vpc" {
  description              = "Allow IT VPC to communicate with MYSQL/Aurora"
  from_port                = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.dev-rds-sg.id
  cidr_blocks              = [var.itvpc_cidr_block]
  to_port                  = 3306
  type                     = "ingress"
}

resource "aws_eks_cluster" "dev" {

  name     = var.cluster-name
  role_arn = aws_iam_role.dev-cluster.arn
  version  = var.eks_version
  #enabled_cluster_log_types = ["api", "audit", "scheduler", "controllerManager"]

  tags = {
    Name        = "eks-develop",
    OWNER       = "SURESH",
    ENVIRONMENT = "DEVELOPMENT"
    FUNCTION    = "EKS-DEV",
    PRODUCT     = "EKS-DEV",
    TEAM        = "DEVOPS",
  }

  vpc_config {
    endpoint_private_access        = true
    endpoint_public_access         = false
    security_group_ids             = [aws_security_group.dev-cluster-sg.id]
    subnet_ids                     = aws_subnet.private-dev[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.dev-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.dev-cluster-AmazonEKSServicePolicy,
  ]
}
