output "jeremie_access_key_id" {
  value       = aws_iam_access_key.jeremie.id
  sensitive   = true
  description = "Access key ID for Jeremie"
}

output "jeremie_secret_access_key" {
  value       = aws_iam_access_key.jeremie.secret
  sensitive   = true
  description = "Secret key for Jeremie"
}

resource "aws_iam_access_key" "students" {
  for_each = aws_iam_user.students
  user     = each.value.name
}

output "students_access_key_ids" {
  value = {
    for user, key in aws_iam_access_key.students :
    user => key.id
  }
  sensitive   = true
  description = "Access key IDs for all students"
}

output "students_secret_access_keys" {
  value = {
    for user, key in aws_iam_access_key.students :
    user => key.secret
  }
  sensitive   = true
  description = "Secret keys for all students"
}

