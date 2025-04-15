#tfsec:ignore:aws-ecr-enforce-immutable-repository
resource "aws_ecr_repository" "golang_terraform" {
  name         = "golang-terraform"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.golang_terraform.arn
  }
}

resource "aws_ecr_lifecycle_policy" "example" {
  repository = aws_ecr_repository.golang_terraform.name

  policy = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Keep last 30 release tagged images",
        "selection": {
          "tagStatus": "tagged",
          "tagPrefixList": ["release"],
          "countType": "imageCountMoreThan",
          "countNumber": 30
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
EOF
}
