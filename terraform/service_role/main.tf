data "aws_iam_policy_document" "iam_policy_document" {
  statement {
    actions = var.policy_document.actions
    effect    = var.policy_document.effect
    principals {
      type        = var.policy_document.type
      identifiers = var.policy_document.identifiers
    }
  }
}

resource "aws_iam_role" "iam_role" {
  name               = var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.iam_policy_document.json
}

data "aws_iam_policy" "iam_policy" {
  arn = var.iam_policy_arn
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment" {
  role       = aws_iam_role.iam_role.name
  policy_arn = data.aws_iam_policy.iam_policy.arn
}