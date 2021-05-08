# tfkube
Terraform Kubernetes example

```
terraform init
terraform apply -var-file=env/demo.tfvars
```

You'll also probably want to install this so you can use your local aws creds to authenticate to your new K8s cluster:
https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html


This will give the pods IAM access to the test-bucket-demo-eks-spot bucket.  

You can list its contents this command from the deployment2 pod:
```
aws s3api list-objects --bucket=test-bucket-demo-eks-spot
```

Boto3 and other AWS SDK's will have the same access.  