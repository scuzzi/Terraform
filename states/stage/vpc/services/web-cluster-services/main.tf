provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket         = "terraform-up-and-running-tutorial"
    key            = "stage/services/web-cluster-services/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}

module "webserver_cluster" {
    source = "../../../../modules/services/web-cluster-services"
    cluster_name = "webservers-stage"
    db_remote_state_bucket = "terraform-up-and-running-tutorial"
    db_remote_state_key = "stage/data-storage/mysql/terraform.tfstate"

    instance_type = "t2.micro"
    min_size = 2
    max_size = 2 
}