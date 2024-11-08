resource "aws_secretsmanager_secret" "ncbi_entrez" {
  name        = "${var.environment}/ncbi-entrez"
  description = "NCBI credentials for identification before making API calls."
  kms_key_id  = "alias/aws/secretsmanager"
}


resource "aws_secretsmanager_secret" "adfs" {
  name        = "${var.environment}/adfs"
  description = "Microsoft ENTRA ID identification values for setting up authentication via OIDC and django-auth-adfs."
  kms_key_id  = "alias/aws/secretsmanager"
}

# Do not put dollar sign in the crypto string otherwise django-environ will fail to import the value properly
# Do not put the hash either for the sake of it
resource "random_password" "cryptographically_strong" {
  length           = 40
  special          = true
  override_special = "!%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "django" {
  name        = "${var.environment}/django-secret-key"
  description = "Holding the cryptographically strong string to be used for Django's SECRET_KEY."
  kms_key_id  = "alias/aws/secretsmanager"
}

resource "aws_secretsmanager_secret_version" "django" {
  secret_id     = resource.aws_secretsmanager_secret.django.id
  secret_string = resource.random_password.cryptographically_strong.result
}
