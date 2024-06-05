resource "aws_iam_role" "gitlab" {
  name = "demo-${var.name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          AWS = "${aws_iam_role.vault.arn}"
        }
      }
    ]
  })
}
