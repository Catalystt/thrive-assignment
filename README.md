# thrive-assignment
Terraform to deploy an IAM roles/polcies, VPC and an EKS cluster.


With a simple node application of hello-world
CI/CD is done with building with CircleCi, and push onto DockerHub, and have it deployed onto the cluster with FluxCD.


CircleCI Setup

In your CircleCI project's settings there is a page to configure environment variables. We'll need a variable named DOCKERHUB_USERNAME with the value of your username, and one named DOCKERHUB_PASS with the value of a personal access token  created for CircleCI. I would recommend against saving your password in plaintext.


Monitoring and Logging will be through Grafana and Prometheus.

SSL certificates with cert-bot.