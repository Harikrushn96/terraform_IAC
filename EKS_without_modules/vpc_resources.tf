# main vpc

resource "aws_vpc" "tf_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "tf_vpc"
  }
}

# internet gateway
resource "aws_internet_gateway" "TF_igw" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "TF_igw"
  }
}

# private subnets
resource "aws_subnet" "private-1a" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = "10.0.0.0/19"
  availability_zone = "us-east-1a"

  tags = {
    Name                              = "private-1a"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/tf_eks"    = "owned"
  }
}

resource "aws_subnet" "private-1b" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = "10.0.32.0/19"
  availability_zone = "us-east-1b"

  tags = {
    Name                              = "private-1b"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/tf_eks"    = "owned"
  }
}

# public subnets
resource "aws_subnet" "public-1a" {
  vpc_id                  = aws_vpc.tf_vpc.id
  cidr_block              = "10.0.64.0/19"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true


  tags = {
    Name                              = "public-1a"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/tf_eks"    = "owned"
  }
}


resource "aws_subnet" "public-1b" {
  vpc_id                  = aws_vpc.tf_vpc.id
  cidr_block              = "10.0.96.0/19"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                              = "public-1b"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/tf_eks"    = "owned"
  }
}

# elastic IP for Natgateway
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "nat"
  }
}

# Natgateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-1a.id

  tags = {
    "name" = "nat"
  }

  depends_on = [aws_eip.nat]
}

# private route table
resource "aws_route_table" "private-1" {
  vpc_id = aws_vpc.tf_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }


  tags = {
    "name" = "private-1"
  }
}

# public route table
resource "aws_route_table" "public-1" {
  vpc_id = aws_vpc.tf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TF_igw.id
  }

  tags = {
    "name" = "public-1"
  }
}

# private_route_table association
resource "aws_route_table_association" "private-1a" {
  subnet_id      = aws_subnet.private-1a.id
  route_table_id = aws_route_table.private-1.id
}

resource "aws_route_table_association" "private-1b" {
  subnet_id      = aws_subnet.private-1b.id
  route_table_id = aws_route_table.private-1.id
}

# public_route_table association
resource "aws_route_table_association" "public-1a" {
  subnet_id      = aws_subnet.public-1a.id
  route_table_id = aws_route_table.public-1.id
}

resource "aws_route_table_association" "public-1b" {
  subnet_id      = aws_subnet.public-1b.id
  route_table_id = aws_route_table.public-1.id
}


# security group for public subnets
resource "aws_security_group" "public_sg" {
  name        = "public-sg"
  description = "Allow web and ssh traffic"
  vpc_id      = aws_vpc.tf_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# security group for private subnets
resource "aws_security_group" "private_sg" {
  name        = "private-sg"
  description = "Allow web tier and ssh traffic"
  vpc_id      = aws_vpc.tf_vpc.id

  # for database mysql
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/16"]
    security_groups = [aws_security_group.public_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "controller_sg" {
  name        = "controller-sg"
  description = "security group for master node"
  vpc_id      = aws_vpc.tf_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


