######### connect a private instance to a public instance #####
resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.one.id
  cidr_block = "10.0.16.0/20"
  availability_zone = "us-east-1a"

  tags = {
    Name = "PrivateSubnetA"
  }
}

resource "aws_instance" "private" {
  ami = "ami-0715c1897453cabd1"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "demo"
  vpc_security_group_ids = [aws_security_group.allow_bastion.id]
  subnet_id = aws_subnet.private1.id

  tags = {
    Name = "private"
  }
}

resource "aws_security_group" "allow_bastion" {
  name        = "privateSG"
  description = "allow SSH from the bastion host"
  vpc_id      = aws_vpc.one.id


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" #any protocol
    cidr_blocks      = ["0.0.0.0/0"] #any IP address
  }

  tags = {
    Name = "allow_bastion"
  }
}

resource "aws_security_group_rule" "allow_SG" {
  type              = "ingress"
  security_group_id = aws_security_group.allow_bastion.id
  description = "SSH"
  from_port        = 22
  to_port          = 22
  protocol         = "tcp"
  source_security_group_id  = aws_security_group.allow_tls.id
}