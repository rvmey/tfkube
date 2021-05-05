# tfkube
Terraform Kubernetes example

```
terraform init
terraform apply -var-file=env/demo.tfvars
```

You'll also probably want to install this so you can use your local aws creds to authenticate to your new K8s cluster:
https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html