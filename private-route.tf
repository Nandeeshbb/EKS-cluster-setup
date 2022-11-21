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


