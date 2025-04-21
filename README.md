# thrive-assignment
Terraform to deploy an IAM roles/polcies, VPC and an EKS cluster.


With a simple node application of hello-world
CI/CD is done with building with CircleCi, and push onto DockerHub, and have it deployed onto the cluster with FluxCD.



# Requirements:
AWS 
Terraform
git
DockerHub
CircleCi


# Spin Up VPC and EKS Cluster
git clone https://github.com/Catalystt/thrive-assignment.git
cd terraform
terraform init
terraform plan
terraform apply





# AWS CLI Setup
With a fresh AWS account you'll need to setup a AWS Access Key and Secret Access Key for your cli user in IAM. Under Users > Create access key > Check CLI
Editting ~/.aws/credentials to have another profile is probably the easiest method.

[default]
aws_access_key_id=DANY08141327EXAMPLE
aws_secret_access_key=dAnYBayMAxEÑXpkJsy/KPxRfiCYEXAMPLElKEY

[user2]
aws_access_key_id=YOUR_ACCESS_KEY
aws_secret_access_key=YOUR_SECRET_ACCESS_KEY

Once that's done you can run: export AWS_PROFILE=user2
Now your AWS CLI should be configured with the new accont






# CircleCI Setup
In your CircleCI project's settings there is a page to configure environment variables. We'll need a variable named DOCKERHUB_USERNAME with the value of your username, and one named DOCKERHUB_PASS with the value of a personal access token  created for CircleCI. I would recommend against saving your password in plaintext.


Monitoring and Logging will be through Grafana and Prometheus.

SSL certificates with cert-bot. Add secrets manager access through cluster.