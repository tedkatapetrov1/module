# Create a VPC ----------------------------------------------------------------
resource "aws_vpc" "my_vpc_01" {
  cidr_block = "172.16.0.0/16"
  tags = {
    Name = "my-exam-vpc"
  }
}

# Create 4 Subnets ------------------------------------------------------------
resource "aws_subnet" "my_public_subnet_01" {
  vpc_id            = aws_vpc.my_vpc_01.id
  cidr_block        = lookup(var.cidr_ranges, "public1")
  availability_zone = lookup(var.regions, "first_zone")
  tags = {
    Name = "${lookup(var.subnet_type, "public")}-subnet01"
  }
}

resource "aws_subnet" "my_public_subnet_02" {
  vpc_id            = aws_vpc.my_vpc_01.id
  cidr_block        = lookup(var.cidr_ranges, "public2")
  availability_zone = lookup(var.regions, "second_zone")
  tags = {
    Name = "${lookup(var.subnet_type, "public")}-subnet02"
  }
}

resource "aws_subnet" "my_private_subnet_01" {
  vpc_id            = aws_vpc.my_vpc_01.id
  cidr_block        = lookup(var.cidr_ranges, "private1")
  availability_zone = lookup(var.regions, "first_zone")
  tags = {
    Name = "${lookup(var.subnet_type, "private")}-private01"
  }
}

resource "aws_subnet" "my_private_subnet_02" {
  vpc_id            = aws_vpc.my_vpc_01.id
  cidr_block        = lookup(var.cidr_ranges, "private2")
  availability_zone = lookup(var.regions, "second_zone")
  tags = {
    Name = "${lookup(var.subnet_type, "private")}-private02"
  }
}

# Create a IGW ----------------------------------------------------------------
resource "aws_internet_gateway" "my_igw_01" {
  vpc_id = aws_vpc.my_vpc_01.id
  tags = {
    name = "my-igw-01"
  }
}

# Create 2 ElasticIP ---------------------------------------------------------
resource "aws_eip" "terraform_elip" {
  domain = "vpc"
}

resource "aws_eip" "terraform_elip2" {
  domain = "vpc"
}

# Create 2 NAT Gateway --------------------------------------------------------
resource "aws_nat_gateway" "my_nat_01" {
  allocation_id = aws_eip.terraform_elip.id
  subnet_id     = aws_subnet.my_public_subnet_01.id
  tags = {
    Name = "my-nat-01"
  }
}

resource "aws_nat_gateway" "my_nat_02" {
  allocation_id = aws_eip.terraform_elip2.id
  subnet_id     = aws_subnet.my_public_subnet_02.id
  tags = {
    Name = "my-nat-02"
  }
}

# Create 4 Routing Tables -----------------------------------------------------
resource "aws_route_table" "my_route_table_01" {
  vpc_id = aws_vpc.my_vpc_01.id
  route {
    cidr_block = var.allow_traffic_cidr_block
    gateway_id = aws_internet_gateway.my_igw_01.id
  }
}

resource "aws_route_table" "my_route_table_02" {
  vpc_id = aws_vpc.my_vpc_01.id
  route {
    cidr_block     = var.allow_traffic_cidr_block
    nat_gateway_id = aws_nat_gateway.my_nat_01.id
  }
}

resource "aws_route_table" "my_route_table_03" {
  vpc_id = aws_vpc.my_vpc_01.id
  route {
    cidr_block = var.allow_traffic_cidr_block
    gateway_id = aws_internet_gateway.my_igw_01.id
  }
}

resource "aws_route_table" "my_route_table_04" {
  vpc_id = aws_vpc.my_vpc_01.id
  route {
    cidr_block     = var.allow_traffic_cidr_block
    nat_gateway_id = aws_nat_gateway.my_nat_02.id
  }
}

# Assosiate Routing Tables ----------------------------------------------------
resource "aws_route_table_association" "my_subnet_assoc_01" {
  subnet_id      = aws_subnet.my_public_subnet_01.id
  route_table_id = aws_route_table.my_route_table_01.id
}

resource "aws_route_table_association" "my_subnet_assoc_02" {
  subnet_id      = aws_subnet.my_private_subnet_01.id
  route_table_id = aws_route_table.my_route_table_02.id
}

resource "aws_route_table_association" "my_subnet_assoc_03" {
  subnet_id      = aws_subnet.my_public_subnet_02.id
  route_table_id = aws_route_table.my_route_table_03.id
}

resource "aws_route_table_association" "my_subnet_assoc_04" {
  subnet_id      = aws_subnet.my_private_subnet_02.id
  route_table_id = aws_route_table.my_route_table_04.id
}