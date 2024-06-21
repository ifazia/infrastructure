############### EKS CLUSTER #############################

# Create an EKS Cluster 
resource "aws_eks_cluster" "petclinic_eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_iam_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  }

  depends_on = [
    aws_iam_role.eks_iam_role,
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.petclinic_eks_cluster.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"  
  resolve_conflicts_on_update = "OVERWRITE"  
  tags = {
    "eks_addon" = "kube-proxy"
  }
  depends_on = [
    aws_eks_cluster.petclinic_eks_cluster
  ]
}

resource "aws_eks_addon" "core_dns" {
  cluster_name                = aws_eks_cluster.petclinic_eks_cluster.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"  
  resolve_conflicts_on_update = "OVERWRITE" 
  tags = {
    "eks_addon" = "coredns"
  }
  depends_on = [
    aws_eks_cluster.petclinic_eks_cluster
  ]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.petclinic_eks_cluster.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"  
  resolve_conflicts_on_update = "OVERWRITE" 
  tags = {
    "eks_addon" = "vpc-cni"
  }
  depends_on = [
    aws_eks_cluster.petclinic_eks_cluster
  ]
}

# Récupérer l'URL de l'OpenID Connect Provider de l'EKS
data "aws_eks_cluster" "auth" {
  name = aws_eks_cluster.petclinic_eks_cluster.name

  depends_on = [
    aws_eks_cluster.petclinic_eks_cluster
  ]
}

# Définir le fournisseur OpenID Connect pour l'EKS
resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = []
  url             = aws_eks_cluster.petclinic_eks_cluster.identity.0.oidc.0.issuer
}
data "aws_iam_policy_document" "assume_role_policy" {
  # Définissez ici votre politique d'assomption de rôle IAM
  # Par exemple :
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "lb_role" {
  name               = "petclinic_eks_lb"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  ]
}

resource "kubernetes_service_account" "service-account" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"               = aws_iam_role.lb_role.arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }

  depends_on = [
    aws_iam_role.lb_role
  ]
}

resource "helm_release" "alb-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  depends_on = [
    kubernetes_service_account.service-account
  ]
}

resource "helm_release" "kube-prometheus-stack" {
  name             = "prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  set {
    name  = "grafana.adminPassword"
    value = var.GRAFANA_PASSWORD
  }

  set {
    name  = "grafana.ingress.enabled"
    value = "true"
  }

  set {
    name  = "grafana.ingress.ingressClassName"
    value = "alb"
  }

  set {
    name  = "grafana.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    value = "internet-facing"
  }

  set {
    name  = "grafana.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
    value = "ip"
  }

  depends_on = [
    kubernetes_service_account.service-account,
    helm_release.alb-controller
  ]
}
