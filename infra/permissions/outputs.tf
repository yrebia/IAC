# --- GitHub Actions OIDC Role ---
output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions_role.arn
  description = "ARN of the IAM Role used by GitHub Actions via OIDC"
}

output "jeremie_access_key_id" {
  value       = aws_iam_access_key.jeremie.id
  sensitive   = true
  description = "Access key ID for Jérémie"
}

output "jeremie_secret_access_key" {
  value       = aws_iam_access_key.jeremie.secret
  sensitive   = true
  description = "Secret access key for Jérémie"
}

output "jeremie_console_username" {
  value       = data.aws_iam_user.jeremie.user_name
  description = "Nom d'utilisateur IAM de Jérémie"
}

output "jeremie_console_password" {
  value       = aws_iam_user_login_profile.jeremie_console.password
  sensitive   = true
  description = "Initial console password for Jérémie"
}

# Access key IDs (pour usage EKS, etc.)
output "students_access_key_ids" {
  value = {
    for user, key in aws_iam_access_key.students :
    user => key.id
  }
  sensitive   = true
  description = "Access key IDs for student IAM users"
}

# Secret keys (sensibles, rarement affichées)
output "students_secret_access_keys" {
  value = {
    for user, key in aws_iam_access_key.students :
    user => key.secret
  }
  sensitive   = true
  description = "Secret access keys for student IAM users"
}

# Liste simple des noms d’utilisateurs (utile pour debug ou affichage)
output "students_usernames" {
  value       = [for user in aws_iam_user.students : user.name]
  description = "List of student IAM usernames"
}
