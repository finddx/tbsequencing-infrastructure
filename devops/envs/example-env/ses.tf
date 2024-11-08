resource "aws_ses_email_identity" "reply_email" {
  email = var.no_reply_email
}
