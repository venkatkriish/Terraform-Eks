terraform {
backend "s3" {
encrypt = true
bucket = "terraform-state-store-ireland"
#dynamodb_table = "terraform-state-lock-dynamo"
region = "eu-west-1"
key = "jd-modules-vpc-k8s-state-s3.tfstate"
}
}