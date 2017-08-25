#--------------------------------------------------------------
# Recipe
# 
# + configure aws region
# + get module vpc
#--------------------------------------------------------------

# + configure aws region
provider "aws" {
    region = "eu-west-1"
}

# + get module vpc
module "vpc" {
  source  = "../../modules/vpc"

  name    = "${ var.project }-${ terraform.workspace }"
  cidr    = "${ var.cidr }"

  azs     = "${ var.azs }"

  private_subnets       = "${ var.private_subnets }"
  public_subnets        = "${ var.public_subnets }"
  
  vpn_subnet            = "${ var.vpn_subnet }"

  enable_nat_gateway    = "${ var.enable_nat_gateway }"
  enable_dns_hostnames  = "${ var.enable_dns_hostnames }"
  enable_dns_support    = "${ var.enable_dns_support }"

  tags {
      workspace     = "${ terraform.workspace }"
      project       = "${ var.project }"
  }
}
