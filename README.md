# thrive-assignment
Terraform to deploy an IAM roles/polcies, VPC and an EKS cluster.


With a simple node application of hello-world
CI/CD is done with building with CircleCi, and push onto DockerHub, and have it deployed onto the cluster with FluxCD.


The Amazon VPC CNI plugin for Kubernetes is deployed with each of your EC2 Nodes in a Daemonset with the name aws-node.

## Limitations
The Amazon VPC CNI plugin for Kubernetes is deployed with each of your EC2 Nodes in a Daemonset with the name aws-node. Using this plugin allows Kubernetes Pods to have the same IP address inside the pod as they do on the VPC network.
This is a great feature but it introduces a limitation in the number of Pods per EC2 Node instance. Whenever you deploy a Pod in the EKS worker Node, EKS creates a new IP address from VPC subnet and attach to the instance. You can find here https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html#AvailableIpPerENI the maximum number of network interfaces and maximum number of IPs per interface.


## Requirements:
AWS 
Terraform
git
DockerHub
CircleCi


## Spin Up VPC and EKS Cluster
```
git clone https://github.com/Catalystt/thrive-assignment.git
cd terraform
terraform init
terraform plan
terraform apply
```

You can generate or update your local kubeconfig file using the AWS CLI. This command will fetch the connection details for your cluster and add them to your kubeconfig (typically located at ~/.kube/config).

aws eks update-kubeconfig --name my-cluster --region ca-central-1
kubectl get nodes


## Testing Deployment
```
kubectl port-forward svc/hello-world-service 3000:80
```


## AWS CLI Setup
With a fresh AWS account you'll need to setup a AWS Access Key and Secret Access Key for your cli user in IAM. Under Users > Create access key > Check CLI
Editting ~/.aws/credentials to have another profile is probably the easiest method.

[default]
aws_access_key_id=DANY08141327EXAMPLE
aws_secret_access_key=dAnYBayMAxEÑXpkJsy/KPxRfiCYEXAMPLElKEY

[user2]
aws_access_key_id=YOUR_ACCESS_KEY
aws_secret_access_key=YOUR_SECRET_ACCESS_KEY

Once that's done you can run: export AWS_PROFILE=user2
Check your access with: aws s3api list-buckets 
Now your AWS CLI should be configured with the new account






## CircleCI Setup (Doesn't deploy to EKS cluster)
In your CircleCI project's settings there is a page to configure environment variables. We'll need a variable named DOCKERHUB_USERNAME with the value of your username, and one named DOCKERHUB_PASS with the value of a personal access token  created for CircleCI. I would recommend against saving your password in plaintext.


Monitoring and Logging will be through Grafana and Prometheus.
I wanted to also implement Grafana and Prometheus for logging/metrics but due to the restriction on the number of pods I am unable to.
Instead we'll setup Cloudwatch:
```
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml
kubectl apply -f k8s/cwagent-configmap-enhanced.yaml
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-daemonset.yaml
```

Once the pod for cloudwatch-agent is running, you should see a new log group appear in Cloudwatch, and you can look through metrics in Cloudwatch for each worker node. 


## SSL certificates with cert-bot. Add secrets manager access through cluster.
Unable to implement due to nodes being t3.micro, unable to allocate pods for cert-manager. (Ingress and service already setup for it)
```
helm repo add cert-manager https://charts.jetstack.io
helm repo update
helm install cert-manager cert-manager/cert-manager --namespace cert-manager --create-namespace --version v1.11.0 --set installCRDs=true
kubectl apply -f k8s/cluster-issuer.yaml
```
