variable "target_host" {
  description = "Target host IP address or hostname"
  type        = string
  default     = "192.168.122.217"
}

variable "target_user" {
  description = "SSH user for target host"
  type        = string
  default     = "root"
}

variable "target_port" {
  description = "SSH port for target host"
  type        = number
  default     = 22
}

variable "target_password" {
  description = "SSH password for target host (optional, prefer SSH keys)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "instance_id" {
  description = "Instance ID for tracking reinstallations"
  type        = string
  default     = ""
}

variable "debug_logging" {
  description = "Enable debug logging"
  type        = bool
  default     = true
}

variable "build_on_remote" {
  description = "Build the closure on the remote machine instead of locally"
  type        = bool
  default     = false
}

variable "phases" {
  description = "Deployment phases to run"
  type        = list(string)
  default     = ["kexec", "disko", "install", "reboot"]
}

variable "extra_environment" {
  description = "Extra environment variables for deployment"
  type        = map(string)
  default     = {}
} 