# create aws vpn gateway for EKS Development VPC
resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = aws_vpc.development.id

  tags = {
    Name        = "dev-eks-vpn-gateway",
    OWNER       = "SONY",
    TEAM        = "IT",
    ENVIRONMENT = "DEVELOPMENT",
    FUNCTION    = "EKS-DEV",
    PRODUCT     = "EKS-DEV"
  }
}
