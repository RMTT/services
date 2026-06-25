locals {
  cfg = nonsensitive(yamldecode(file("config.yaml")))
}
