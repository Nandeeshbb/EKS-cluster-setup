resource "aws_route" "nat_gtw" {
 count = length(var.private_subnets)
 route_table_id = element(aws_route_table.private-dev.*.id,count.index)
 destination_cidr_block = "0.0.0.0/0"
 nat_gateway_id = element(aws_nat_gateway.gw.*.id,count.index)
}

resource "aws_route" "nat_gtw_db" {
 count = length(var.private_subnets_db)
 route_table_id = element(aws_route_table.private-dev-db.*.id,count.index)
 destination_cidr_block = "0.0.0.0/0"
 nat_gateway_id = element(aws_nat_gateway.gw.*.id,count.index)
}

# resource "aws_route" "vpn_gtw" {
#  count = length(var.private_subnets)
#  route_table_id = element(aws_route_table.private-dev.*.id,count.index)
#  destination_cidr_block = var.office_ntw
#  gateway_id = aws_vpn_gateway.vpn_gw.id
# }

# resource "aws_route" "vpn_gtw_db" {
#  count = length(var.private_subnets_db)
#  route_table_id = element(aws_route_table.private-dev-db.*.id,count.index)
#  destination_cidr_block = var.office_ntw
#  gateway_id = aws_vpn_gateway.vpn_gw.id
# }

# resource "aws_route" "prod_vpn_dynamic" {
#  route_table_id = aws_route_table.private-dev.id
#  destination_cidr_block = var.vpn_dynamic_cidr
#  vpc_peering_connection_id = aws_vpc_peering_connection.eks2prodvpc.id
# }

# resource "aws_route" "prod_vpn_static" {
#  route_table_id = aws_route_table.private-dev.id
#  destination_cidr_block = var.vpn_static_cidr
#  vpc_peering_connection_id = aws_vpc_peering_connection.eks2prodvpc.id
# }

# resource "aws_route" "eks2privateprodvpc" {
#  route_table_id = aws_route_table.private-dev.id
#  destination_cidr_block = var.prodvpc-cidr-block
#  vpc_peering_connection_id = aws_vpc_peering_connection.eks2prodvpc.id

# }
