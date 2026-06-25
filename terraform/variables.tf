variable "import" {
  type        = bool
  default     = false
  description = "If true, import all existing DNS records to dynamic resources; otherwise, only manage configured local records."
}
