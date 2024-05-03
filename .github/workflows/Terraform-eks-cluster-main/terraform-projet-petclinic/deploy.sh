
#!/bin/bash

terraform apply -auto-approve
export cluster_name=petclinic-eks-cluster
oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4
eksctl utils associate-iam-oidc-provider --cluster $cluster_name --approve
aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4
