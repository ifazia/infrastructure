################## VPC AND NETWORKING #############################
# Create a VPC
resource "aws_vpc" "petclinic_vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "petclinic-vpc"
  }
}

# create two public subnets resources
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.petclinic_vpc.id
  cidr_block              = var.cidr_public_subnet_a
  map_public_ip_on_launch = "true"
  availability_zone       = var.az_a

  tags = {
    Name = "petclinic-public-subnet-a"
  }
  depends_on = [
    aws_vpc.petclinic_vpc,
  ]
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.petclinic_vpc.id
  cidr_block              = var.cidr_public_subnet_b
  map_public_ip_on_launch = "true"
  availability_zone       = var.az_b

  tags = {
    Name = "petclinic-public-subnet-b"
  }
  depends_on = [
    aws_vpc.petclinic_vpc,
  ]
}

resource "aws_ec2_tag" "public_subnet_cluster_tag_a" {
  resource_id = aws_subnet.public_subnet_a.id
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "owned"
}

resource "aws_ec2_tag" "public_subnet_cluster_tag_b" {
  resource_id = aws_subnet.public_subnet_b.id
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "owned"
}


resource "aws_ec2_tag" "public_subnet_tag_a" {
  resource_id = aws_subnet.public_subnet_a.id
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_subnet_tag_b" {
  resource_id = aws_subnet.public_subnet_b.id
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

# create an internet gateway for our vpc
resource "aws_internet_gateway" "petclinic_internet_gateway" {
  vpc_id = aws_vpc.petclinic_vpc.id

  tags = {
    Name = "petclinic-internet-gateway"
  }
  depends_on = [
    aws_vpc.petclinic_vpc,
  ]
}

# create a route table for public subnets
resource "aws_route_table" "route_table_public" {
  vpc_id = aws_vpc.petclinic_vpc.id

  tags = {
    Name = "petclinic-public-route-table"
  }
  depends_on = [
    aws_vpc.petclinic_vpc,
  ]
}

# create a route to the internet gateway
resource "aws_route" "route_igw" {
  route_table_id         = aws_route_table.route_table_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.petclinic_internet_gateway.id
}

# Attach public subnet a to route table
resource "aws_route_table_association" "route_table_subnet_association_pub_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.route_table_public.id
}

# Attach public subnet b to route table
resource "aws_route_table_association" "rta_subnet_association_pubb" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.route_table_public.id
}
