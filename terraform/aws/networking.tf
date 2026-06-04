############################################
# VPC Configuration
############################################

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-vpc"
    }
  )
}

############################################
# VPC Flow Logs
############################################

resource "aws_flow_log" "main" {
  count               = var.enable_flow_logs ? 1 : 0
  resource_type       = "VPC"
  resource_id         = aws_vpc.main.id
  traffic_type        = "ALL"
  log_destination     = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn        = aws_iam_role.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-vpc-flow-logs"
    }
  )

  depends_on = [
    aws_iam_role_policy.vpc_flow_logs,
    aws_cloudwatch_log_group.vpc_flow_logs
  ]
}

resource "aws_ec2_network_insights_path" "vpc_flow" {
  count      = var.enable_flow_logs ? 1 : 0
  source     = aws_vpc.main.id
  destination = aws_vpc.main.id
  protocol   = "tcp"
}

############################################
# Internet Gateway
############################################

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

############################################
# Public Subnets
############################################

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index % local.az_count]
  map_public_ip_on_launch = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-public-subnet-${count.index + 1}"
      Tier = "Public"
    }
  )
}

############################################
# Private Subnets
############################################

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index % local.az_count]

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-private-subnet-${count.index + 1}"
      Tier = "Private"
    }
  )
}

############################################
# Elastic IPs for NAT Gateway
############################################

resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? length(var.private_subnet_cidrs) : 0
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-eip-nat-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

############################################
# NAT Gateway
############################################

resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? length(var.private_subnet_cidrs) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-nat-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

############################################
# Route Tables - Public
############################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-public-rt"
      Tier = "Public"
    }
  )
}

resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

############################################
# Route Tables - Private
############################################

resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway ? length(var.private_subnet_cidrs) : 1
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-private-rt-${count.index + 1}"
      Tier = "Private"
    }
  )
}

resource "aws_route" "private_nat" {
  count              = var.enable_nat_gateway ? length(var.private_subnet_cidrs) : 0
  route_table_id     = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id     = aws_nat_gateway.main[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index % length(aws_route_table.private)].id
}

############################################
# VPN Gateway (Optional)
############################################

resource "aws_vpn_gateway" "main" {
  count  = var.enable_vpn ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-vpn-gateway"
    }
  )
}

resource "aws_vpn_gateway_route_propagation" "public" {
  count              = var.enable_vpn ? 1 : 0
  vpn_gateway_id     = aws_vpn_gateway.main[0].id
  route_table_id     = aws_route_table.public.id
}

resource "aws_vpn_gateway_route_propagation" "private" {
  count              = var.enable_vpn ? length(aws_route_table.private) : 0
  vpn_gateway_id     = aws_vpn_gateway.main[0].id
  route_table_id     = aws_route_table.private[count.index].id
}

############################################
# Network ACLs (Additional Security Layer)
############################################

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-public-nacl"
    }
  )
}

resource "aws_network_acl_rule" "public_inbound_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.allowed_public_cidrs[0]
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_inbound_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.allowed_public_cidrs[0]
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "public_outbound_http_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 443
  egress         = true
}

resource "aws_network_acl_rule" "private" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "private_outbound" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
  egress         = true
}
