####################vpc-peering connection in a different region #############################
provider "aws" {
  alias  = "central"
  region = "us-west-1"
}

resource "aws_vpc" "one" {
  cidr_block = "10.0.0.0/16"
  tags ={
    Name = "VPC-1"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.one.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "publicSubnet"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.one.id

  tags = {
    Name = "igw1"
  }
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.one.id


  ingress {
    description = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      =  ["0.0.0.0/0"]

  }
  ingress {
    description = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      =  ["0.0.0.0/0"]

  }
  ingress {
    description = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      =  ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" #any protocol
    cidr_blocks      = ["0.0.0.0/0"] #any IP address
  }

  tags = {
    Name = "allow_web"
  }
}


resource "aws_route_table" "example" {
  vpc_id = aws_vpc.one.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  route {
    cidr_block = "10.2.0.0/16"
    vpc_peering_connection_id  = aws_vpc_peering_connection.vpcpeering.id
  }
  tags = {
    Name = "eastroute"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.example.id
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = aws.central
  vpc_peering_connection_id = aws_vpc_peering_connection.vpcpeering.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}
resource "aws_vpc_peering_connection" "vpcpeering" {
  peer_vpc_id   = aws_vpc.two.id
  vpc_id        = aws_vpc.one.id
  peer_region   = "us-west-1"
  auto_accept = false

  tags = {
      "Name" = "vpc_peering"
  }
}
resource "aws_vpc" "two" {
  provider   = aws.central
  cidr_block = "10.2.0.0/16"
  tags ={
    Name = "VPC-2"
  }
}


resource "aws_security_group" "allow_web2" {
  name        = "allow_web_traffic"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.two.id
  provider   = aws.central


  ingress {
    description = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      =  ["0.0.0.0/0"]

  }
  ingress {
    description = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      =  ["0.0.0.0/0"]

  }
  ingress {
    description = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      =  ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" #any protocol
    cidr_blocks      = ["0.0.0.0/0"] #any IP address
  }

  tags = {
    Name = "allow_web2"
  }
}

resource "aws_internet_gateway" "gw2" {
  vpc_id = aws_vpc.two.id
  provider = aws.central

  tags = {
    Name = "igw2"
  }
}

resource "aws_route_table" "westroute" {
  vpc_id = aws_vpc.two.id
  provider = aws.central
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw2.id
  }
  route {
    cidr_block = "10.0.0.0/16"
    vpc_peering_connection_id  = aws_vpc_peering_connection.vpcpeering.id
  }
  tags = {
    Name = "ewestroute"
  }
}

resource "aws_subnet" "westsubnet" {
  provider = aws.central
  vpc_id     = aws_vpc.two.id
  cidr_block = "10.2.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-1a"
  depends_on = [aws_internet_gateway.gw2]

  tags = {
    Name = "publicSubnet2"
  }
}


resource "aws_route_table_association" "b" {
  provider = aws.central
  subnet_id      = aws_subnet.westsubnet.id
  route_table_id = aws_route_table.westroute.id
}