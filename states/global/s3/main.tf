provider "aws" {
    region = "us-east-2"
}

#S3 Bucket Creation
resource "aws_s3_bucket" "terraform_state" {
    bucket = "terraform-up-and-running-tutorial"
    #prevent accidental deletion
    lifecycle {
        prevent_destroy = true
    }
}

#versioning
resource "aws_s3_bucket_versioning" "enabled" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
        status = "Enabled"
    }

}

#Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
    bucket = aws_s3_bucket.terraform_state.id
    rule {
        apply_server_side_encryption_by_default{
            sse_algorithm = "AES256"
        }
    }
}

#S3 Block public access to s3 bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
    bucket = aws_s3_bucket.terraform_state.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true

}


#DynamoDB table creation 
resource "aws_dynamodb_table" "terraform_locks" {
    name = "terraform-up-and-running-locks"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"
    
    attribute {
        name = "LockID"
        type = "S"
    }

}


output "s3_bucket_arn" {
    value       = aws_s3_bucket.terraform_state.arn
    description = "ARN of S3 Bucket"
}

output "dynamodb_table_name" {
    value = aws_dynamodb_table.terraform_locks.name
    description = "Name of the DynamoDB table."

}


