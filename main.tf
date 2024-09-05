terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.65.0"
    }
  }

  /*backend "local" {
    path = "terraform.tfstate"
  }*/

  backend "s3" {
    bucket = "314522435747-tf-state"
    dynamodb_table = "314522435747-tf-state"
    region = "eu-central-1"
    key = "terraform.tfstate"
    encrypt = true
    profile = "user"
    role_arn = "arn:aws:iam::314522435747:role/deploy"
  }

}

provider "aws" {
  region = local.region
  profile = "user"

  // role for subsequent use
  assume_role {
    role_arn = "arn:aws:iam::${local.account_id}:role/deploy"
  }
}

provider aws {
  region = "us-east-1"
  profile = "user"
  alias = "us-east-1"

  // role for subsequent use
  assume_role {
    role_arn = "arn:aws:iam::${local.account_id}:role/deploy"
  }
}

