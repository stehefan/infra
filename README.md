# Infrastructure Setup for AWS Account

## Initial Setup

Start the initial setup with `local`-Backend and the `profile` setting in 
the AWS Provider activated to use your user for setting up the IAM-Role
to use subsequently.

Run the following steps:

```shell
terraform init
terraform apply # check output and confirm with yes
```

Afterwards, you should have createda a new role `deploy` that will be used
to deploy remaining resources. For this, remove the comment from the
`assume_role`-setting block in `main.tf` and use the created role for all 
steps following.

Now, let's create the state-management related resources:

```shell
terraform apply # check output and confirm with yes
```

Now the state-bucket and -table have been created and we can switch to 
a remote state. Remove the comment around `backend "s3"` and comment out 
`backend "local"` and run the following

```shell
terraform init
```

Confirm with `yes` when asked to and wait for the process to finish.

From now on, all state will be stored in the S3-Bucket and you can use the
`deploy`-role for all further infrastructure deployments.
