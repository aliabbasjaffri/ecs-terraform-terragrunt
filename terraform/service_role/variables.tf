variable "policy_document" {
  type = object({
    actions = list(string)
    effect = string
    type = string
    identifiers = list(string)
  })
}

variable "iam_role_name" {
  type = string
}

variable "iam_policy_arn" {
  type = string
}

