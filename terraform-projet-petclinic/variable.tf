# varible for the vpc IP range
variable "cidr_vpc" {
  description = "VPC CIDR"
  default     = "10.0.0.0/16"
}


# varibles four our 2 AZs in region eu-west-3
variable "az_a" {
  description = "Availaility zone a"
  default     = "eu-west-3a"
}

variable "az_b" {
  description = "Availaility zone b"
  default     = "eu-west-3b"
}

# cidr variable for the four subnets
variable "cidr_public_subnet_a" {
  description = "CIDR for public subnet a"
  default     = "10.0.0.0/24"
}

variable "cidr_public_subnet_b" {
  description = "CIDR for public subnet b"
  default     = "10.0.1.0/24"
}

variable "DB_USERNAME" {
 description = "Database username"
 type    = string
 sensitive = true
}
variable "DB_PASSWORD" {
 description = "Database password"
 type    = string
 sensitive = true
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster"
  default = "petclinic-eks-cluster"
}

variable "aws_region" {
  type        = string
  description = "AWS region where secrets are stored."
  default = "eu-west-3"
}
variable "access_key" {
  type    = string
  default = "$AWS_ACCESS_KEY_ID"
}

variable "secret_key" {
  type    = string
  default = "$AWS_SECRET_ACCESS_KEY"
}

# cidr variable for the four subnets
variable "cidr_private_subnet_a" {
  description = "CIDR for public subnet a"
  default     = "10.0.16.0/24"
}

variable "cidr_private_subnet_b" {
  description = "CIDR for public subnet b"
  default     = "10.0.144.0/24"
}
variable "subnets_private" {
  description = "Map of private subnets"
  default = {
    subnet_a = ""
    subnet_b = ""
  }
}
variable "GRAFANA_PASSWORD" {
 description = "Grafana password"
 type    = string
 sensitive = true
}
variable "vpc_id" {
  description = "ID de la VPC utilisée par le cluster EKS"
  type        = string
}