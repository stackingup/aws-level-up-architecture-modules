variable "region" {}
variable "account-name" {}
variable "vpc-cidr-block" {}
variable "default-tags" {
  type = "map"
  default = {}
}
variable "eu-west-2a-nat-gateway-eip-alloc-id" {
  description = "The Elastic IP Allocation ID to associate with the eu-west-2a Availability Zone of the eu-west-2 region"
}
variable "eu-west-2b-nat-gateway-eip-alloc-id" {
  description = "The Elastic IP Allocation ID to associate with the eu-west-2b Availability Zone of the eu-west-2 region"
}

