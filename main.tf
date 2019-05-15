provider "aws" {
    region = "${var.aws_region}"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

data "aws_ami" "server_ami" {
    most_recent = true
    
    owners = ["amazon"]

    filter {
        name = "owner-alias"
        values = ["amazon"]
    }
    filter {
        name = "name"
        values = ["amzn-ami-hvm*-x86_64-gp2"]
    }
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "tf_vpc" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    enable_dns_support = true
    
    tags {
        Name = "tf_vpc"
    }
}

resource "aws_internet_gateway" "tf_internet_gateway" {
    vpc_id = "${aws_vpc.tf_vpc.id}"
    tags {
        Name = "tf_igw"
    }
}

resource "aws_route_table" "tf_public_rt" {
    vpc_id = "${aws_vpc.tf_vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.tf_internet_gateway.id}"
    }
    tags {
        Name = "tf_public"
    }
}

resource "aws_default_route_table" "tf_private_rt" {
    default_route_table_id = "${aws_vpc.tf_vpc.default_route_table_id}"
    tags {
        Name = "tf_private"
    }
}

resource "aws_subnet" "tf_public_subnet" {
    vpc_id = "${aws_vpc.tf_vpc.id}"
    cidr_block = "${var.public_cidr}"
    map_public_ip_on_launch = true
#    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    
    tags {
        Name = "tf_public_subnet"
    }
}

resource "aws_subnet" "tf_private_subnet" {
    vpc_id = "${aws_vpc.tf_vpc.id}"
    cidr_block = "${var.private_cidr}"
    map_public_ip_on_launch = false
#    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    
    tags {
        Name = "tf_private_subnet"
    }
}

resource "aws_route_table_association" "tf_public_assoc" {
    subnet_id = "${aws_subnet.tf_public_subnet.id}"
    route_table_id = "${aws_route_table.tf_public_rt.id}"
}

resource "aws_route_table_association" "tf_private_assoc" {
    subnet_id = "${aws_subnet.tf_private_subnet.id}"
    route_table_id = "${aws_default_route_table.tf_private_rt.id}"
}

resource "aws_security_group" "tf_public_sg" {
    name = "tf_public_sg"
    description = "Used for the access to the public instances"
    vpc_id = "${aws_vpc.tf_vpc.id}"
    
    ingress {
        from_port = "22"
        to_port = "22"
        protocol = "tcp"
        cidr_blocks = ["${var.accessip}"]
    }
    
    ingress {
        from_port = "80"
        to_port = "80"
        protocol = "tcp"
        cidr_blocks = ["${var.accessip}"]
    }
    
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
}

resource "aws_security_group" "tf_private_sg" {
    name = "tf_private_sg"
    description = "Security group for the private instance"
    vpc_id = "${aws_vpc.tf_vpc.id}"
    
    ingress {
        from_port = "0"
        to_port = "0"
        protocol = "-1"
        cidr_blocks = ["${aws_instance.tf_public_server.private_ip}/32"]
    }
    
    ingress {
        from_port = "23"
        to_port = "23"
        protocol = "tcp"
        cidr_blocks = ["${var.accessip}"]
    }
    
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
}

resource "aws_instance" "tf_public_server" {
    instance_type = "${var.instance_type}"
    ami = "${data.aws_ami.server_ami.id}"
    tags {
        Name = "tf_server-public"
        
    }
    key_name = "tfsankus"
    vpc_security_group_ids = ["${aws_security_group.tf_public_sg.id}"]
    subnet_id = "${aws_subnet.tf_public_subnet.id}"
    #user_data = "${data.template_file.user_init.*.rendered[count.index]}"

    provisioner "local-exec" {
        command = "sleep 120; ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u ec2-user -i '${aws_instance.tf_public_server.public_ip},' --private-key ./tfsankus.pem nginx_install.yaml" 
    }
}

data "template_file" "init" {
  template = "${file("${path.module}/init.tpl")}"
}

resource "aws_instance" "tf_private_server" {
    instance_type = "${var.instance_type}"
    ami = "${data.aws_ami.server_ami.id}"
    tags {
        Name = "tf_server-private"
        
    }
    key_name = "tfsankus"
    vpc_security_group_ids = ["${aws_security_group.tf_private_sg.id}"]
    subnet_id = "${aws_subnet.tf_private_subnet.id}"
    associate_public_ip_address = false
    user_data = "${data.template_file.init.rendered}"
}

resource "aws_eip" "tf_eip" {
  instance = "${aws_instance.tf_public_server.id}"
}

