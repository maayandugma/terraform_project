resource "aws_vpc" "one" {
  cidr_block = "10.0.0.0/16"

  tags ={
    Name = "demo-vpc"
  }
}

resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.one.id
  map_public_ip_on_launch = true
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "PublicSubnetA"
  }
}

resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.one.id
  cidr_block = "10.0.16.0/20"
  availability_zone = "us-east-1a"

  tags = {
    Name = "PrivateSubnetA"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.one.id

  tags = {
    Name = "public"
  }
}

resource "aws_instance" "web" {
  ami = "ami-0715c1897453cabd1"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "ec2Tutorial"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  subnet_id = aws_subnet.public1.id
  associate_public_ip_address = true

  user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt install apache2 -y
            sudo systemctl start apache2
            systemctl enable httpd
            sudo bash -c "echo Hello World from  > /var/www/html/index.html"
            EOF
  tags = {
    Name = "public"
  }
}


resource "aws_security_group" "allow_tls" {
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

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.one.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}