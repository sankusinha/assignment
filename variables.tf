variable "aws_region" {}

variable vpc_cidr {
    default = "10.0.0.0/16"
}

variable aws_access_key {}
variable aws_secret_key {}

variable public_cidr {
    default = "10.0.1.0/24"
}

variable private_cidr {
    default = "10.0.2.0/24"
}

variable accessip {
    default = "0.0.0.0/0"
}

variable key_name {
    default = "tf_aws_global"
}

variable public_key {
    default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2H/oNsRmRYjYpPUhiHQNZ6RMkAwijUpDe1Ou5eBBJbbnHZN53W5DahgERghSAY+q4RAN1NRX5+aGEV8hSToQJlJ6i/nU3XoyOAtU9CUPZGQgMdinSRPn3p1Owwok0OncvoJaNc9HELxEts+XYgbqzQ+r/nuVdRGCC1p6idiX6XvzbQrQfHhrbJ6sMr50m1t9yjm5qEcizfhqYT4K6csjoR4GZbzKEra31uIO7FbJOhWJRgSLCg05MOjR21QTNq++JoNIccPYX2W5gL8yL0B0ncFCC4ETWZxjzjuzspqwfe6QaB5lV5e84rE9hAa4wrGbs5fujzkRgxz3kJKdAg2d9 ec2-user@ip-172-31-18-52"
}

variable "instance_type" {
    default = "t2.micro"
}

variable "ssh_key_private" {}