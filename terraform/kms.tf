resource "aws_kms_key" "golang_terraform" {
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "golang-terraform" {
  name          = "alias/golang-terraform"
  target_key_id = aws_kms_key.golang_terraform.key_id
}

# data "aws_kms_secrets" "secrets" {
#   dynamic "secret" {
#     for_each = local.secrets

#     content {
#       name    = secret.key
#       payload = secret.value
#     }
#   }
# }
