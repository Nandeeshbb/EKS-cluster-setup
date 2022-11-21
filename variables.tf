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
    default = ["10.20.0.0/22", "10.20.4.0/22", "10.20.8.0/22"]
}

variable "firewall_public_subnets" {
    type    = list
    default = ["10.20.12.0/22", "10.20.16.0/22", "10.20.20.0/22"]
}

variable "private_subnets" {
    type    = list
    default = ["10.20.32.0/20", "10.20.48.0/20", "10.20.64.0/20"]
}

variable "private_subnets_db" {
    type    = list
    default = ["10.20.80.0/20", "10.20.96.0/20", "10.20.112.0/20"]
}



