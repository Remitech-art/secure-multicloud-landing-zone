terraform {
  backend "s3" {
    bucket         = "secure-multicloud-terraform-state"
    key            = "aws/landing-zone/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "secure-multicloud-terraform-locks"
  }
}
