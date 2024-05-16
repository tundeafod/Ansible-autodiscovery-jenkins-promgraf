terraform {
  backend "s3" {
    bucket         = "tfstate-tspadp"
    key            = "tspadp-server/tfstate"
    dynamodb_table = "tspadp-backend"
    region         = "eu-west-2"
    encrypt        = true
    profile        = "team1"
  }
}
