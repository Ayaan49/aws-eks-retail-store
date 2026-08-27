# Use existing AWS Secrets Manager Secret (already created manually)
data "aws_secretsmanager_secret" "retailstore_secret" {
  name = "retailstore-db-secret-1"
}

data "aws_secretsmanager_secret_version" "retailstore_secret_value" {
  secret_id = data.aws_secretsmanager_secret.retailstore_secret.id
}

locals {
  retailstore_secret_json = jsondecode(data.aws_secretsmanager_secret_version.retailstore_secret_value.secret_string)
}
