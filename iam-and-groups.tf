resource "aws_iam_role" "dev-node" {
  name = "terraform-eks-development-node"

  assume_role_policy = <<POLICY
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
POLICY
}

## Kube2IAM - allow worker to assume all roles
resource "aws_iam_role_policy" "kube2iam_worker_policy" {
  name = "kube2iam_worker_policy"
  role = aws_iam_role.dev-node.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

###
##  Allow worker nodes to send memory metrics to cloudwatch
resource "aws_iam_role_policy" "mem_scaling_worker_policy" {
  name = "mem_scaling_worker_policy"
  role = aws_iam_role.dev-node.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:PutMetricData",
        "ec2:DescribeTags",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dev-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.dev-node.name
}

resource "aws_iam_role_policy_attachment" "dev-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.dev-node.name
}

resource "aws_iam_role_policy_attachment" "dev-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.dev-node.name
}

resource "aws_iam_instance_profile" "dev-node" {
  name = "terraform-eks-develop"
  role = aws_iam_role.dev-node.name
}

resource "aws_security_group" "dev-node" {
  name        = "terraform-eks-dev-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.development.id

  tags = {
    Name                                        = "dev-eks-node-sg",
    "kubernetes.io/cluster/${var.cluster-name}" = "owned",
    OWNER                                       = "SURESH",
    FUNCTION                                    = "EKS-DEV",
    PRODUCT                                     = "EKS-DEV",
    TEAM                                        = "DEVOPS",
  }
}

##### OUTGOING TRAFFIC RESTRICTED

# resource "aws_security_group_rule" "dev-node-egress-itvpc" {
#   from_port                = 0
#   protocol                 = "-1"
#   security_group_id        = aws_security_group.dev-node.id
#   cidr_blocks              = [var.itvpc_cidr_block]
#   to_port                  = 0
#   type                     = "egress"
# }

# resource "aws_security_group_rule" "dev-node-egress-self-vpc" {
#   from_port                = 0
#   protocol                 = "-1"
#   security_group_id        = aws_security_group.dev-node.id
#   cidr_blocks              = [var.vpc_cidr_block]
#   to_port                  = 0
#   type                     = "egress"
# }

# resource "aws_security_group_rule" "dev-node-egress-https" {
#   from_port                = 443
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.dev-node.id
#   cidr_blocks              = ["0.0.0.0/0"]
#   to_port                  = 443
#   type                     = "egress"
# }

# resource "aws_security_group_rule" "dev-node-egress-http" {
#   from_port                = 80
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.dev-node.id
#   cidr_blocks              = ["0.0.0.0/0"]
#   to_port                  = 80
#   type                     = "egress"
# }

resource "aws_security_group_rule" "dev-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.dev-node.id
  source_security_group_id = aws_security_group.dev-node.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "dev-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.dev-node.id
  source_security_group_id = aws_security_group.dev-cluster-sg.id
  to_port                  = 65535
  type                     = "ingress"
}

# HPA requires 443 to be open for k8s control plane
resource "aws_security_group_rule" "dev-node-ingress-hpa-https" {
  description              = "Allow HPA to receive communication from the cluster control plane"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.dev-node.id
  source_security_group_id = aws_security_group.dev-cluster-sg.id
  to_port                  = 443
  type                     = "ingress"
}

# HPA requires 80 to be open for k8s control plane
resource "aws_security_group_rule" "dev-node-ingress-hpa-http" {
  description              = "Allow HPA to receive communication from the cluster control plane"
  from_port                = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.dev-node.id
  source_security_group_id = aws_security_group.dev-cluster-sg.id
  to_port                  = 80
  type                     = "ingress"
}

resource "aws_security_group_rule" "dev-node-ingress-itvpc" {
  description              = "Allow traffic from IT VPC"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.dev-node.id
  cidr_blocks              = [var.itvpc_cidr_block]
  to_port                  = 0
  type                     = "ingress"
}

resource "aws_security_group_rule" "dev-node-ingress-self-vpc" {
  description              = "Allow node to communicate within VPC"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.dev-node.id
  cidr_blocks              = [aws_vpc.development.cidr_block]
  to_port                  = 0
  type                     = "ingress"
}
