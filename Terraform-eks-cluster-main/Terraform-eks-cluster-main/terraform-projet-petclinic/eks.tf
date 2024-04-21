
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