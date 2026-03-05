# ============================================================
# Terraform Variables - WireGuard VPN (vpn.tf 전용)
# ============================================================

# ============================================================
# 1. EC2 인스턴스 타입
# ============================================================
variable "instance_type" {
  description = "EC2 instance type for WireGuard bastion"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^t[234]g?\\.", var.instance_type))
    error_message = "Instance type must be a t-type (t3, t3a, t4g, etc.)"
  }
}

# ============================================================
# 2. WireGuard VPN 활성화 여부
# ============================================================
variable "enable_wireguard" {
  description = "Enable WireGuard VPN deployment"
  type        = bool
  default     = true
}

# ============================================================
# 3. WireGuard 프로토콜 설정
# ============================================================
variable "wireguard_config" {
  description = "WireGuard configuration"
  type = object({
    port = number
    mtu  = number
  })

  default = {
    port = 51820
    mtu  = 1420
  }

  validation {
    condition     = var.wireguard_config.port >= 1024 && var.wireguard_config.port <= 65535
    error_message = "WireGuard port must be between 1024 and 65535."
  }
}

# ============================================================
# 4. SSH 접근 제어 (CIDR 블록)
# ============================================================
variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access to WireGuard bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  # ⚠️ 프로덕션에서는 반드시 특정 IP로 제한할 것!
  # 예: ["203.0.113.0/32", "198.51.100.0/24"]

  validation {
    condition = alltrue([
      for cidr in var.allowed_ssh_cidrs : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", cidr))
    ])
    error_message = "All allowed_ssh_cidrs must be valid CIDR blocks."
  }
}

# ============================================================
# 5. WireGuard 클라이언트 설정
# ============================================================
variable "wireguard_client_configs" {
  description = "WireGuard client configurations to generate"
  type = map(object({
    address = string
  }))

  default = {
    client1 = {
      address = "10.0.0.2/32"
    }
    client2 = {
      address = "10.0.0.3/32"
    }
  }
}

# ============================================================
# 6. 공통 리소스 태그
# ============================================================
variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)

  default = {
    Environment = "dev"
    Project     = "usinsa"
    ManagedBy   = "terraform"
  }
}
