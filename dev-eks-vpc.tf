#
# EKS VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "development" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
     Name = "Dev",
     "kubernetes.io/cluster/${var.cluster-name}" = "shared",
  }
}

## EKS public subnets protected by firewalls

resource "aws_subnet" "public-dev" {
  count = length(var.public_subnets)

  availability_zone               = data.aws_availability_zones.available.names[count.index]
  cidr_block                      = var.public_subnets[count.index]
  vpc_id                          = aws_vpc.development.id
  map_public_ip_on_launch         = true

  tags = {
     Name                                        = "dev-eks-public-firewall-protected-subnet",
     "kubernetes.io/cluster/${var.cluster-name}" = "shared",
     "kubernetes.io/role/elb"                    = "1",
     Environment                                 = "Prod",
  }
}

## EKS public subnets for firewalls

resource "aws_subnet" "firewall-public-dev" {
  count = length(var.firewall_public_subnets)

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.firewall_public_subnets[count.index]
  vpc_id            = aws_vpc.development.id

    tags = {
     Name = "dev-eks-public-firewall-subnet",
    }
}

## internet gateway

resource "aws_internet_gateway" "dev" {
  vpc_id = aws_vpc.development.id

  tags = {
    Name = "dev-eks-igw"
  }
}

## public routing table, routing table association

resource "aws_route_table" "public-dev" {
  vpc_id = aws_vpc.development.id

  tags = {
        Name        = "dev-public-firewall-route-table"
    }
}

resource "aws_route" "internet_gateway" {
  route_table_id              = aws_route_table.public-dev.id
  destination_cidr_block      = "0.0.0.0/0"
  gateway_id                  = aws_internet_gateway.dev.id
}

resource "aws_route_table_association" "public-dev" {
  count = length(var.public_subnets)

  subnet_id      = aws_subnet.firewall-public-dev.*.id[count.index]
  route_table_id = aws_route_table.public-dev.id
}

## EKS private subnets

resource "aws_subnet" "private-dev" {
  count = length(var.private_subnets)

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.private_subnets[count.index]
  vpc_id            = aws_vpc.development.id

  tags = {
    Name                                        = "dev-eks-private-app-subnet",
    "kubernetes.io/cluster/${var.cluster-name}" = "shared",
    "kubernetes.io/role/internal-elb"           = "1"
  }
}

## Private subnets for databases

resource "aws_subnet" "private-dev-db" {
  count = length(var.private_subnets_db)

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.private_subnets_db[count.index]
  vpc_id            = aws_vpc.development.id
  tags = {
    Name        = "dev-eks-private-db-subnet"
  }  

}

resource "aws_route_table" "private-dev-db" {
  vpc_id = aws_vpc.development.id
  count = length(var.private_subnets_db)
  
  tags = {
    Name        = "dev-private-db-route-table"
  }
}

resource "aws_route_table_association" "private-dev-db" {
  count = length(var.private_subnets_db)

  subnet_id      = element(aws_subnet.private-dev-db.*.id,count.index)
  route_table_id = element(aws_route_table.private-dev-db.*.id,count.index)
}

resource "aws_eip" "nat" {
  count  = length(var.public_subnets)
  vpc    = true
}

resource "aws_nat_gateway" "gw" {
  count = length(var.public_subnets)
  allocation_id = element(aws_eip.nat.*.id,count.index)
  subnet_id = element(aws_subnet.public-dev.*.id,count.index)
  tags = {
    Name = "dev-public-firewall-protected-natgw-${count.index + 1}"
  }
}

## private routing table, routing table association
resource "aws_route_table" "private-dev" {
  vpc_id = aws_vpc.development.id

  # route {
  #   cidr_block = "0.0.0.0/0"
  #   gateway_id = "${aws_nat_gateway.gw.*.id}"
  # }

#  route {
#    cidr_block = "${var.office_ntw}"
#    gateway_id = "${aws_vpn_gateway.vpn_gw.id}"
#   }

#  route {
#    cidr_block = "${var.vpn_dynamic_cidr}" # variables.tf
#    vpc_peering_connection_id = "${aws_vpc_peering_connection.eks2prodvpc.id}"
#  }

#  route {
#    cidr_block = "${var.vpn_static_cidr}" # variables.tf
#    vpc_peering_connection_id = "${aws_vpc_peering_connection.eks2prodvpc.id}"
#  }
 
#  route {
#    cidr_block = "${var.prodvpc-cidr-block}" # variables.tf
#    vpc_peering_connection_id = "${aws_vpc_peering_connection.eks2prodvpc.id}"
#  }

count = length(var.private_subnets)

  tags = {
        Name        = "dev-private-route-table"
    }
}

resource "aws_route_table_association" "private-dev" {
  count = length(var.private_subnets)

  subnet_id      = element(aws_subnet.private-dev.*.id,count.index)
  route_table_id = element(aws_route_table.private-dev.*.id,count.index)
}

# data "aws_caller_identity" "current" {}

# resource "aws_vpc_endpoint_service" "gateway_load_balancer" {
#   acceptance_required        = false
#   allowed_principals         = [data.aws_caller_identity.current.arn]
#   gateway_load_balancer_arns = [aws_lb.example.arn]
# }

# resource "aws_vpc_endpoint" "example" {
#   service_name      = aws_vpc_endpoint_service.gateway_load_balancer.service_name
#   subnet_ids        = [aws_subnet.firewall-public-dev.id]
#   vpc_endpoint_type = GatewayLoadBalancer
#   vpc_id            = aws_vpc.development.id
# }

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.development.id
  service_name = "com.amazonaws.us-east-1.s3"

  tags = {
    Name        = "dev-s3-vpc-endpoint"
  }
}

resource "aws_flow_log" "dev-flowlog" {
  iam_role_arn    = aws_iam_role.flowlogs-role.arn
  log_destination = aws_cloudwatch_log_group.flowlogs-log-group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.development.id
  max_aggregation_interval = 600
}

resource "aws_cloudwatch_log_group" "flowlogs-log-group" {
  name = "eks-develop-vpc-flowlogs"
  retention_in_days = 365
}

resource "aws_iam_role" "flowlogs-role" {
  name = "EKSDevFlowlogsRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "flowlogs-policy" {
  name = "example"
  role = aws_iam_role.flowlogs-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
