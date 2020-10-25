locals {
  region = "us-west-2"

  tags = {
    Stack       = "tf-remote-state"
    Provisioner = "terraform"
  }
}
