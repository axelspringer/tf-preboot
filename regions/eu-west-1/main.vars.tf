#--------------------------------------------------------------
# This configures all resources in AWS eu-west-1 region
#
# !hint these are loaded via envs
#--------------------------------------------------------------

variable "project"          { }

variable "cidr"             { default = "172.16.0.0/16" }
variable "private_subnets"  { default = ["172.16.0.0/23"] }
variable "public_subnets"   { default = ["172.16.2.0/23"] }
variable "vpn_subnet"       { default = "172.16.254.0/23" }

variable "enable_dns_hostnames" { default = false }
variable "enable_dns_support"   { default = true }
variable "enable_nat_gateway"   { default = true }

variable "azs"              { default = ["eu-west-1c"] }
