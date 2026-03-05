# Terraform Configuration for AWS Infrastructure
# Provider configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    # SSH 키 자동 생성용
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    # Private Key 로컬 저장용
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Kubernetes Provider
data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.this.name
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(
    data.aws_eks_cluster.this.certificate_authority[0].data
  )
  token = data.aws_eks_cluster_auth.this.token
}

# Helm Provider
provider "helm" {
  kubernetes {
    host = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(
      data.aws_eks_cluster.this.certificate_authority[0].data
    )
    token = data.aws_eks_cluster_auth.this.token
  }
}


# VPC
resource "aws_vpc" "usinsa" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = var.project_name
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "usinsa_igw" {
  vpc_id = aws_vpc.usinsa.id

  tags = {
    Name      = "${var.project_name}-igw"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# Elastic IP (NAT용)
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name      = "${var.project_name}-nat-eip"
    Project   = var.project_name
    ManagedBy = "terraform"
  }

  depends_on = [aws_internet_gateway.usinsa_igw]
}

# Public Subnets
resource "aws_subnet" "usinsa_public_2a" {
  vpc_id                  = aws_vpc.usinsa.id
  cidr_block              = "10.0.0.0/20"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.project_name}-public-2a"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    Project                                     = var.project_name
    ManagedBy                                   = "terraform"
  }
}

resource "aws_subnet" "usinsa_public_2b" {
  vpc_id                  = aws_vpc.usinsa.id
  cidr_block              = "10.0.16.0/20"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.project_name}-public-2b"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    Project                                     = var.project_name
    ManagedBy                                   = "terraform"
  }
}

# Private Subnets
resource "aws_subnet" "usinsa_private_2a" {
  vpc_id            = aws_vpc.usinsa.id
  cidr_block        = "10.0.128.0/20"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name                                        = "${var.project_name}-private-2a"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
    Project                                     = var.project_name
    ManagedBy                                   = "terraform"
  }
}

resource "aws_subnet" "usinsa_private_2b" {
  vpc_id            = aws_vpc.usinsa.id
  cidr_block        = "10.0.144.0/20"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name                                        = "${var.project_name}-private-2b"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
    Project                                     = var.project_name
    ManagedBy                                   = "terraform"
  }
}

# Public Route Table
resource "aws_route_table" "usinsa_public_rt" {
  vpc_id = aws_vpc.usinsa.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.usinsa_igw.id
  }

  tags = {
    Name      = "${var.project_name}-public-rt"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# Private Route Table 1
resource "aws_route_table" "usinsa_private_rt1" {
  vpc_id = aws_vpc.usinsa.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name      = "${var.project_name}-private-rt1"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# Private Route Table 2
resource "aws_route_table" "usinsa_private_rt2" {
  vpc_id = aws_vpc.usinsa.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name      = "${var.project_name}-private-rt2"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# Route Table Associations - Public Subnets
resource "aws_route_table_association" "public_2a" {
  subnet_id      = aws_subnet.usinsa_public_2a.id
  route_table_id = aws_route_table.usinsa_public_rt.id
}

resource "aws_route_table_association" "public_2b" {
  subnet_id      = aws_subnet.usinsa_public_2b.id
  route_table_id = aws_route_table.usinsa_public_rt.id
}

# Route Table Associations - Private Subnets
resource "aws_route_table_association" "private_2a" {
  subnet_id      = aws_subnet.usinsa_private_2a.id
  route_table_id = aws_route_table.usinsa_private_rt1.id
}

resource "aws_route_table_association" "private_2b" {
  subnet_id      = aws_subnet.usinsa_private_2b.id
  route_table_id = aws_route_table.usinsa_private_rt2.id
}

# VPC Endpoint for S3
resource "aws_vpc_endpoint" "usinsa_s3_endpoint" {
  vpc_id       = aws_vpc.usinsa.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  route_table_ids = [
    aws_route_table.usinsa_public_rt.id,
    aws_route_table.usinsa_private_rt1.id,
    aws_route_table.usinsa_private_rt2.id
  ]

  tags = {
    Name      = "${var.project_name}-s3-endpoint"
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.usinsa_public_2a.id

  tags = {
    Name      = "${var.project_name}-nat"
    Project   = var.project_name
    ManagedBy = "terraform"
  }

  depends_on = [aws_internet_gateway.usinsa_igw]
}

# namespace resource add
resource "kubernetes_namespace" "shop" {
  metadata {
    name = "shop"
  }

  depends_on = [aws_eks_node_group.this]
}

# HPA Install (metric)
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"

  values = [
    file("${path.module}/metrics-server-values.yaml")
  ]

  depends_on = [aws_eks_node_group.this]
}

# HPA Install (Kubernetes HPA v2)
resource "kubernetes_horizontal_pod_autoscaler_v2" "shop_hpa" {
  depends_on = [
    kubernetes_deployment.shop
  ]

  metadata {
    name      = "shop-hpa"
    namespace = kubernetes_namespace.shop.metadata[0].name
  }

  spec {
    min_replicas = 2
    max_replicas = 4

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.shop.metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = 60
        }
      }
    }
  }
}

# HPA Deployment 구성
resource "kubernetes_deployment" "shop" {
  depends_on = [
    kubernetes_namespace.shop,
    helm_release.metrics_server
  ]

  metadata {
    name      = "shop"
    namespace = kubernetes_namespace.shop.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "shop"
      }
    }

    template {
      metadata {
        labels = {
          app = "shop"
        }
      }

      spec {
        container {
          name  = "shop"
          image = "<ECR_URL>:latest"

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }
}
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.usinsa_public_2a.id

  tags = {
    Name = "${var.project}-nat"
  }

  depends_on = [aws_internet_gateway.usinsa_igw]
}

# namespace resource add
resource "kubernetes_namespace" "shop" {
  metadata {
    name = "shop"
  }
}

# HPA Install (metric)

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"

  values = [
    file("${path.module}/metrics-server-values.yaml")
  ]
}

# HPA Install (Kubernetes HPA v2)

resource "kubernetes_horizontal_pod_autoscaler_v2" "shop_hpa" {

depends_on = [
    kubernetes_deployment.shop
  ]

  metadata {
    name      = "shop-hpa"
    namespace = kubernetes_namespace.shop.metadata[0].name
  }

  spec {
    min_replicas = 2
    max_replicas = 4

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.shop.metadata[0].name
    }

    metric {
      type = "Resource"

      resource {
        name = "cpu"

        target {
          type                = "Utilization"
          average_utilization = 60
        }
      }
    }
  }
}



# HPA Deployment 구성

resource "kubernetes_deployment" "shop" {
 depends_on = [
    kubernetes_namespace.shop,
    helm_release.metrics_server
  ]

  metadata {
    name      = "shop"
    namespace = kubernetes_namespace.shop.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "shop"
      }
    }

    template {
      metadata {
        labels = {
          app = "shop"
        }
      }

      spec {
        container {
          name  = "shop"
          image = "<ECR_URL>:latest"

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }
}








