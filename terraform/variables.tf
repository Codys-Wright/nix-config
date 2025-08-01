variable "target_password" {
  description = "SSH password for target host (optional, prefer SSH keys)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "extra_environment" {
  description = "Extra environment variables for deployment"
  type        = map(string)
  default     = {}
} 