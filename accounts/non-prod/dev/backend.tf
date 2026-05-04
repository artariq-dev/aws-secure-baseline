terraform {
  backend "s3" {
    bucket         = "REPLACE_WITH_STATE_BUCKET_NAME"
    key            = "non-prod/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
