variable "cluster-name" {
  default = "eks-develop"
  type    = string
}

variable "eks_version" {
   default = "1.19"
   description = "kubernetes cluster version provided by AWS EKS"
}

variable "public_subnets" {
    type    = list
    default = ["10.16.0.0/22", "10.16.4.0/22", "10.16.8.0/22"]
}

variable "firewall_public_subnets" {
    type    = list
    default = ["10.16.12.0/22", "10.16.16.0/22", "10.16.20.0/22"]
}

variable "private_subnets" {
    type    = list
    default = ["10.16.32.0/20", "10.16.48.0/20", "10.16.64.0/20"]
}

variable "private_subnets_db" {
    type    = list
    default = ["10.16.80.0/20", "10.16.96.0/20", "10.16.112.0/20"]
}

 # variable "aws_profile" {
 #   default = "miq-dev"
 #   description = "which aws cli profile to be used"
 # }

# variable "office_ntw" {
#    default = "192.168.0.0/16"
#    description = "To add this in private subnet route"
# }

# variable "vpn_dynamic_cidr" {
#    default = "172.27.224.0/20"
#    description = "To add this in private subnet route"
# }

# variable "vpn_static_cidr" {
#    default = "172.27.240.0/20"
#    description = "To add this in private subnet route"
# }

### it vpc peering ###

variable "itvpc_cidr_block" {
   type = string
   default = "10.11.0.0/16"
   description = "IT VPC CIDR Block"
}

variable "vpc_cidr_block" {
   type = string
   default = "10.16.0.0/16"
   description = "Development VPC CIDR Block"
}

variable "itvpc_id" {
   default = "vpc-0e3d89d7f54662593"
   description = "IT VPC ID"
}

# variable "itvpc-route-table-id" {
#    default = "" # not available
#    description = "IT VPC private route table ID"

# }

### prod vpc peering ###

# variable "prodvpc-cidr-block" {
#    default = "172.30.0.0/16"
#    description = "Prod VPC CIDR Block"

# }

# variable "prodvpc_id" {
#    default = "vpc-1499e871"
#    description = "Prod VPC ID"

# }

# variable "prodvpc-route-table-id" {
#    default = "rtb-0e03bbd3bb1cbb543"
#    description = "Prod VPC private route table ID"

# }

####Sydney and EKS VPC peering variables###
# variable "sydney-vpc-id" {
#    default = "vpc-0083b44adb8c1a4f1"
#    description = "Sydney VPC id required for peering connection"
# }

# variable "sydneyvpc-route-table-id" {
#    default = "rtb-04ea83c265a999e5d"
#    description = "Private Subnet Routing table of sydney vpc"
# }

# variable "sydneyvpc-cidr-block" {
#    default = "10.212.0.0/16"
#    description = "To add this in private subnet route of sydney VPC"
# }

### ireland vpc peering ###

# variable "ireland-vpc-id" {
#   default = "vpc-0e05bc9259caba2e0"
#   description = "need for eks vpc and ireland VPC peering"
# }

# variable "irelandvpc-route-table-id" {
#    default = "rtb-00379887db1caf1bb"
#    description = "Private Subnet Routing table of ireland vpc"
# }

# variable "irelandvpc-cidr-block" {
#    default = "10.214.0.0/16"
#    description = "To add this in private subnet route of ireland VPC"
# }

