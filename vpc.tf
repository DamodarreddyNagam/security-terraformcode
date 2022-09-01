# create_vpc
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name      = "stage_vpc"
    terraform = "true"
  }
}

#Avilability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

# create public subnets 
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.pub_cidr, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = "true"
  tags = {
    Name = "Stage-Public-${count.index+1}"
  }
}

# create private subnets 
resource "aws_subnet" "private" {
  count = length(data.aws_availability_zones.available.names)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.pri_cidr, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = "true"
  tags = {
    Name = "Stage-Private-${count.index+1}"
  }
}

# create Data subnets 
resource "aws_subnet" "data" {
  count = length(data.aws_availability_zones.available.names)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = element(var.data_cidr, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = "true"
  tags = {
    Name = "Stage-Data-${count.index+1}"
  }
}

#create IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "IGW"
  }
}
#create EIP
resource "aws_eip" "eip" {
  vpc      = true
}

#create Nat Gateway
resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "gw NAT"
  }
}

#create Public Route Tables
resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-Route"
  }
}

#create Public Route Tables
resource "aws_route_table" "private-route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "Private-Route"
  }
}

#create public subnet association
resource "aws_route_table_association" "public" {
  count = length(data.aws_availability_zones.available.names)
  subnet_id = element(aws_subnet.public[*].id,count.index)
  route_table_id = aws_route_table.public-route.id
}

#create private subnet association
resource "aws_route_table_association" "private" {
  count = length(data.aws_availability_zones.available)
  subnet_id = element(aws_subnet.private[*].id,count.index)
  route_table_id = aws_route_table.private-route.id
}

#create data subnet association
resource "aws_route_table_association" "data" {
  count = length(data.aws_availability_zones.available)
  subnet_id = element(aws_subnet.data[*].id,count.index)
  route_table_id = aws_route_table.private-route.id
}