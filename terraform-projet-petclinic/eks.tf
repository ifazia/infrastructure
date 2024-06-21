
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
  cluster_name = aws_eks_cluster.petclinic_eks_cluster.name
  addon_name        = "kube-proxy"
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
  cluster_name = aws_eks_cluster.petclinic_eks_cluster.name
  addon_name        = "coredns"
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
  cluster_name = aws_eks_cluster.petclinic_eks_cluster.name
  addon_name        = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"  
  resolve_conflicts_on_update = "OVERWRITE" 
  tags = {
      "eks_addon" = "vpc-cni"
  }
  depends_on = [
    aws_eks_cluster.petclinic_eks_cluster
  ]
}

module "lb_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                              = "petclinic_eks_lb"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  depends_on = [
    module.eks
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
      "eks.amazonaws.com/role-arn"               = module.lb_role.iam_role_arn
      "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }

  depends_on = [
    module.lb_role
  ]
}

resource "helm_release" "alb-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "region"
    value = "eu-west-3"
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
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
    value = local.cluster_name
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
    helm_release.alb-controller,
    module.vpc
  ]
}