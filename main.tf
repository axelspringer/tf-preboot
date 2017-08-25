#--------------------------------------------------------------
# Recipe
# 
# + set terraform s3 backend
# + set provider aws
# + get module aws eu-west-1 region
#--------------------------------------------------------------

# + set terraform s3 backend
terraform {
  backend "s3" {}
  # we use workspaces
  required_version = ">= 0.10.0"
}

# + set provider aws
provider "aws" {
  access_key  = "${ var.aws_access_key }"
  secret_key  = "${ var.aws_secret_key }"
}

# + get module aws eu-west-1 region
module "eu-west-1" {
  source        = "./regions/eu-west-1"
  project       = "${ var.project }"
}
