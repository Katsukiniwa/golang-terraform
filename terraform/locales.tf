data "aws_availability_zones" "available" {
  state = "available"
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_elb_service_account" "main" {}
data "aws_canonical_user_id" "current" {}

locals {
  account_id         = data.aws_caller_identity.current.account_id
  region             = data.aws_region.current.name
  availability_zones = toset(data.aws_availability_zones.available.names)
  name               = "til"

  az_conf = {
    "ap-northeast-1a" = {
      index      = 1
      short_name = "1a"
    }
    "ap-northeast-1c" = {
      index      = 2
      short_name = "1c"
    }
    "ap-northeast-1d" = {
      index      = 3
      short_name = "1d"
    }
  }

  vpc_cidr = "10.0.0.0/16"
}
