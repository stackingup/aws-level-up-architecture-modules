/*
START: VPC and subnet configuration

Note: For networking principles, approach and an example see README.MD

Example for company-test, using a VPC CIDR block of 10.20.0.0/16, would result in the following being created 
10.20.0.0/16 - VPC (company-test-eu-west-2)
        10.20.0.0/19 - private subnet (10.20.0.0/19-eu-west-2a-private)
               10.20.32.0/20 - public subnet (10.20.32.0/20-eu-west-2a-public)
        10.20.64.0/19 - private subnet (10.20.64.0/19-eu-west-2b-private)
                10.20.96.0/20 - public subnet (10.20.96.0/20-eu-west-2b-public)
*/

resource "aws_vpc" "region-main" {
    cidr_block  = "${var.vpc-cidr-block}"
    tags        = "${merge(var.default-tags, map("Name", "${var.account-name}-eu-west-2"))}"
}

resource "aws_subnet" "eu-west-2a-private" {
    availability_zone   = "eu-west-2a"
    cidr_block          = "${cidrsubnet(aws_vpc.region-main.cidr_block, 3, 0)}"
    vpc_id              = "${aws_vpc.region-main.id}"
    tags = "${merge(var.default-tags, map("Name", "${cidrsubnet(aws_vpc.region-main.cidr_block, 3, 0)}-eu-west-2a-private"), map("company:isPublic", "false"))}"
}

resource "aws_subnet" "eu-west-2a-public" {
    availability_zone   = "eu-west-2a"
    cidr_block          = "${cidrsubnet(aws_vpc.region-main.cidr_block, 4, 2)}"
    vpc_id              = "${aws_vpc.region-main.id}"
    tags = "${merge(var.default-tags, map("Name", "${cidrsubnet(aws_vpc.region-main.cidr_block, 4, 2)}-eu-west-2a-public"), map("company:isPublic", "true"))}"
}

resource "aws_subnet" "eu-west-2b-private" {
    availability_zone   = "eu-west-2b"
    cidr_block          = "${cidrsubnet(aws_vpc.region-main.cidr_block, 3, 2)}"
    vpc_id              = "${aws_vpc.region-main.id}"
    tags = "${merge(var.default-tags, map("Name", "${cidrsubnet(aws_vpc.region-main.cidr_block, 3, 2)}-eu-west-2b-private"), map("company:isPublic", "false"))}"
}

resource "aws_subnet" "eu-west-2b-public" {
    availability_zone   = "eu-west-2b"
    cidr_block          = "${cidrsubnet(aws_vpc.region-main.cidr_block, 4, 6)}"
    vpc_id              = "${aws_vpc.region-main.id}"
    tags = "${merge(var.default-tags, map("Name", "${cidrsubnet(aws_vpc.region-main.cidr_block, 4, 6)}-eu-west-2b-public"), map("company:isPublic", "true"))}"
}

/*
END: VPC and subnet configuration 
*/

/*
START: NAT gateway configuration
* Here we provision a NAT Gateway for each of the private subnets above, associating them with the Elastic IPs configured as variables 
*/
resource "aws_nat_gateway" "eu-west-2a-nat-gateway" {
    allocation_id = "${var.eu-west-2a-nat-gateway-eip-alloc-id}"
    subnet_id     = "${aws_subnet.eu-west-2a-public.id}"
    tags      = "${merge(var.default-tags, map("Name", "eu-west-2a-nat-gateway"))}"
}

resource "aws_nat_gateway" "eu-west-2b-nat-gateway" {
    allocation_id = "${var.eu-west-2b-nat-gateway-eip-alloc-id}"
    subnet_id     = "${aws_subnet.eu-west-2b-public.id}"
    tags      = "${merge(var.default-tags, map("Name", "eu-west-2b-nat-gateway"))}"
}

/*
END: NAT gateway configuration
*/

/*
START: Route table configuration

Example for company-test, using a VPC CIDR block of 10.20.0.0/16, would result in the following being created 

'internal-only' (ie, Protected and Private) routing table
    10.20.0.0/16 - Local	

'public' routing table
    10.20.0.0/16 - Local
    0.0.0.0/0 -  Internet Gateway
*/
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id    = "${aws_vpc.region-main.id}"
  tags      = "${merge(var.default-tags, map("Name", "eu-west-2-public"))}" 
}

resource "aws_route_table" "eu-west-2a-internal" {
    vpc_id = "${aws_vpc.region-main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id  = "${aws_nat_gateway.eu-west-2a-nat-gateway.id}"    
    }  
    tags = "${merge(var.default-tags, map("Name", "eu-west-2a-internal"))}"
}

resource "aws_route_table" "eu-west-2b-internal" {
    vpc_id = "${aws_vpc.region-main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id  = "${aws_nat_gateway.eu-west-2b-nat-gateway.id}"    
    }  
    tags = "${merge(var.default-tags, map("Name", "eu-west-2b-internal"))}"
}

resource "aws_route_table" "public" {
    vpc_id      = "${aws_vpc.region-main.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.internet-gateway.id}"    
    }
    tags      = "${merge(var.default-tags, map("Name", "eu-west-2-public"))}"
}

/*
END: Route table configuration
*/

/*
START: Associate subnets and routing tables
*/
resource "aws_route_table_association" "eu-west-2a-private-internal-association" {
  subnet_id      = "${aws_subnet.eu-west-2a-private.id}"
  route_table_id = "${aws_route_table.eu-west-2a-internal.id}"
}

resource "aws_route_table_association" "eu-west-2b-private-internal-association" {
  subnet_id      = "${aws_subnet.eu-west-2b-private.id}"
  route_table_id = "${aws_route_table.eu-west-2b-internal.id}"
}

resource "aws_route_table_association" "eu-west-2a-public-public-association" {
  subnet_id      = "${aws_subnet.eu-west-2a-public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "eu-west-2b-public-public-association" {
  subnet_id      = "${aws_subnet.eu-west-2b-public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

/*
END: Associate subnets and routing tables
*/

