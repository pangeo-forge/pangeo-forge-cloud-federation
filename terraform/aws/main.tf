terraform {
  backend "s3" {
    # FIXME: Investigate if we need the dynamodb locking here?
    bucket = "pangeo-forge-veda-tfstate"
    key    = "terraform"
    region = "us-west-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags { tags = var.aws_tags }
}

data "aws_vpc" "default" {
  default = var.aws_vpc.default
  id      = var.aws_vpc.id
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

