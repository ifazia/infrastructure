## EKS IAM
# IAM resource that ensures that the role has access to EKS
resource "aws_iam_role" "eks_iam_role" {
  name = "${var.cluster_name}-eks"

  path = "/"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  tags = {
    name = "eks cluster iam role"
  }

}
# The two policies allow you to properly access EC2 instances (where the worker nodes run) and EKS.
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_iam_role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_iam_role.name
}

resource "aws_iam_role_policy_attachment" "AWSCertificateManagerReadOnly-EKS" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCertificateManagerReadOnly"
  role       = aws_iam_role.eks_iam_role.name
}

# Create the worker nodes
resource "aws_eks_node_group" "worker-node-group" {
  cluster_name    = aws_eks_cluster.petclinic_eks_cluster.name
  node_group_name = "${var.cluster_name}-eks-node-group"
  node_role_arn   = aws_iam_role.workernodes.arn
  subnet_ids      = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  instance_types  = ["t3.large"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.AWSCertificateManagerReadOnly-EKS
  ]
}
# Create iam role and policies for our workrer nodes
resource "aws_iam_role" "workernodes" {
  name = "${var.cluster_name}-worker-nodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com",

      }

    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.workernodes.name
}

resource "aws_iam_role_policy_attachment" "AWSCertificateManagerReadOnly-EKS2" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCertificateManagerReadOnly"
  role       = aws_iam_role.workernodes.name
}


## ALB IAM ROLE
resource "aws_iam_policy" "kubernetes_alb_controller" {
  name        = "${var.cluster_name}-alb-controller"
  path        = "/"
  description = "Policy for load balancer controller service"

  policy = file("policy/alb_iam_policy.json")
}

# Role
resource "aws_iam_role" "kubernetes_alb_controller" {
  depends_on = [
    aws_eks_cluster.petclinic_eks_cluster
  ]
  name = "${var.cluster_name}-alb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity",
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::590184139086:oidc-provider/${replace(aws_eks_cluster.petclinic_eks_cluster.identity[0].oidc[0].issuer, "https://", "")}"
        },
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.petclinic_eks_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:alb-ingress-controller",
            "${replace(aws_eks_cluster.petclinic_eks_cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kubernetes_alb_controller" {
  role       = aws_iam_role.kubernetes_alb_controller.name
  policy_arn = aws_iam_policy.kubernetes_alb_controller.arn
}

