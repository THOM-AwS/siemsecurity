terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "location-tf-backend"
    dynamodb_table = "terraform-state-lock-dynamo"
    key            = "terraform.tfstate"
    region         = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.44.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

locals {
  pubkey-tom   = file("${path.module}/key-tom.txt")
  pubkey-awais = file("${path.module}/key-awais.txt")
}
