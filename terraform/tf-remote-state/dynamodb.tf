resource "aws_dynamodb_table" "terraform_state_locks" {
  name           = "terraform-state-locks"
  read_capacity  = 10
  write_capacity = 5
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.tags
}
