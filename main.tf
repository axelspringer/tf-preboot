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
provider "aws" {} // please, set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, or AWS_SHARED_CREDENTIALS_FILE

# + get module aws eu-west-1 region
module "eu-west-1" {
  source        = "./regions/eu-west-1"
  project       = "${ var.project }"
}
