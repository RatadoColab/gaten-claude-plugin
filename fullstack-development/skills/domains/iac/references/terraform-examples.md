# IaC — Exemplos Terraform

## Backend remoto com locking

```hcl
terraform {
  required_version = ">= 1.7"
  backend "s3" {
    bucket         = "company-tf-state"
    key            = "prod/network.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-locks"      # lock contra apply concorrente
    encrypt        = true
  }
}

# Recurso parametrizado e versionado
resource "aws_s3_bucket" "assets" {
  bucket = "app-assets-${var.environment}"
  tags   = { Environment = var.environment, ManagedBy = "terraform" }
}
```
