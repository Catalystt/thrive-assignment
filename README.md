# thrive-assignment
Terraform to deploy an IAM roles/polcies, VPC and an EKS cluster.


With a simple node application of hello-world
CI/CD is done with building with Github Actions, and pushed onto DockerHub, deploying it onto the cluster through each push.
Added an option to use CircleCI but there was no way to have it deploy onto EKS.


![Imgur](https://i.imgur.com/vUm9UIi.png "AWS Architecture")
![Imgur](https://i.imgur.com/gvJ4MdG.png)
![Imgur](http://i.imgur.com/zTONrOD.jpg)
## Limitations
The Amazon VPC CNI plugin for Kubernetes is deployed with each of your EC2 Nodes in a Daemonset with the name aws-node. Using this plugin allows Kubernetes Pods to have the same IP address inside the pod as they do on the VPC network.
This is a great feature but it introduces a limitation in the number of Pods per EC2 Node instance. Whenever you deploy a Pod in the EKS worker Node, EKS creates a new IP address from VPC subnet and attach to the instance. You can find here https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html#AvailableIpPerENI the maximum number of network interfaces and maximum number of IPs per interface.
On a t3.micro we're limited to 4 pods. This makes things very difficult as I wanted to do a lot of things like setup SSL certificates/renewals, ArgoCD or FluxCD for deployments, Grafana and Prometheus for logging/metrics/alerts. 

## Requirements:
* AWS 
* AWS CLI
* Terraform
* git
* DockerHub
* CircleCi (Optional)
* Helm (Optional)

## AWS CLI Setup
We need to create a new user for the CLI. We need three things here: a new policy, a new user, and the access keys.
1. Policy
Policies > Create policy > JSON > Paste the snippet below > Name it cli-policy > Create policy
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EC2FullAccess",
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "ssm:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EKSFullAccess",
            "Effect": "Allow",
            "Action": "eks:*",
            "Resource": "*"
        },
		{
            "Sid": "SSMFullAccess",
            "Effect": "Allow",
            "Action": [
				"ssm:*",
				"logs:*",
				"ec2messages:*"
			],
            "Resource": "*"
        },
        {
            "Sid": "IAMFullAccessForRoles",
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PutRolePolicy",
                "iam:GetRole",
                "iam:PassRole",
                "iam:ListRoles",
				"iam:*
            ],
            "Resource": "*"
        },
        {
            "Sid": "AutoScalingFullAccess",
            "Effect": "Allow",
            "Action": "autoscaling:*",
            "Resource": "*"
        },
        {
            "Sid": "SecretsManagerAccess",
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:ListSecrets",
                "secretsmanager:CreateSecret",
                "secretsmanager:PutSecretValue"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ECRAccess",
            "Effect": "Allow",
            "Action": "ecr:*",
            "Resource": "*"
        },
        {
            "Sid": "CloudWatchAccess",
            "Effect": "Allow",
            "Action": "cloudwatch:*",
            "Resource": "*"
        },
        {
            "Sid": "S3Access",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
```

2. User 
Users > Create user > Name it cli-user > Attach policy directly > Find your newly created cli-policy > Check it > Next > Create user

3. Access Keys
With a fresh AWS account you'll need to setup a AWS Access Key and Secret Access Key for your cli user in IAM. Under Users > Create access key > Check CLI
Editting ~/.aws/credentials to have another profile is probably the easiest method.
```
[default]
aws_access_key_id=DANY08141327EXAMPLE
aws_secret_access_key=dAnYBayMAxEÑXpkJsy/KPxRfiCYEXAMPLElKEY

[user2]
aws_access_key_id=YOUR_ACCESS_KEY
aws_secret_access_key=YOUR_SECRET_ACCESS_KEY
```
Once that's done you can run: ```export AWS_PROFILE=user2```
Check your access with: ```aws s3api list-buckets ```
Now your AWS CLI should be configured with the new account


## DockerHub Setup
You should create your own DockerHub repo for this, and replace the repo in all of the images: 
* ./github/workflow/deploy.yaml:
![Imgur] (https://imgur.com/SVnkPtu)

* ./k8s/deployment.yaml:
![Imgur] (https://imgur.com/vkTuP12)
* ./circleci/config.yaml 

## Github Actions Setup
Make sure you have added the following secrets in your GitHub repository settings under Settings>Environments>production:

- DOCKERHUB_USERNAME
- DOCKERHUB_TOKEN
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION: "ca-central-1"
- CLUSTER_NAME: "devops-cluster" (your EKS cluster’s name)
- NAMESPACE: "default" (the namespace in which your app is deployed)
- DEPLOYMENT_NAME: "hello-world-deployment" (the name of your Kubernetes Deployment)
- CONTAINER_NAME: "hello-world" (the container name within that deployment)


## Spin Up VPC and EKS Cluster
```
git clone https://github.com/Catalystt/thrive-assignment.git
cd terraform
terraform init
terraform plan
terraform apply
```

You can generate or update your local kubeconfig file using the AWS CLI. This command will fetch the connection details for your cluster and add them to your kubeconfig (typically located at ~/.kube/config).
```
aws eks update-kubeconfig --name devops-cluster --region ca-central-1
kubectl get nodes
kubectl get all -A
```
If getting instances cannot join kuberentes cluster error, troubleshoot with https://ca-central-1.console.aws.amazon.com/systems-manager/automation/execute/AWSSupport-TroubleshootEKSWorkerNode?region=ca-central-1
## Deployments/Services
```
kubectl apply -f deployment.yaml
kubectl apply -f deployment_svc.yaml
kubectl apply -f ingress.yaml
kubectl apply -f secrets.yaml
```

## Testing Deployment
```
kubectl port-forward svc/hello-world-service 3000:80
```
From here you can ```curl --v localhost:3000``` or use a browser to hit localhost:3000





## CircleCI Setup (Doesn't deploy to EKS cluster)
In your CircleCI project's settings there is a page to configure environment variables. We'll need a variable named DOCKERHUB_USERNAME with the value of your username, and one named DOCKERHUB_PASS with the value of a personal access token  created for CircleCI. I would recommend against saving your password in plaintext.


## Monitoring and Logging (Cloudwatch)

I wanted to also implement Grafana and Prometheus for logging/metrics but due to the restriction on the number of pods I am unable to.
Instead we'll setup Cloudwatch:
```
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml
kubectl apply -f k8s/cwagent-configmap-enhanced.yaml
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-daemonset.yaml
```

Once the pod for cloudwatch-agent is running, you should see a new log group appear in Cloudwatch, and you can look through metrics in Cloudwatch for each worker node. 

## Alerts 
Currently setup on Cloudwatch to alert on high CPU of a worker node, can change to detect on pod crashing but didn't have enough time. I originally wanted to alert through Grafana/Prometheus and setup a webhook with Slack.

## SSL certificates with cert-bot. Add secrets manager access through cluster.
Unable to implement due to nodes being t3.micro, unable to allocate pods for cert-manager. (Ingress and service already setup for it)
```
helm repo add cert-manager https://charts.jetstack.io
helm repo update
helm install cert-manager cert-manager/cert-manager --namespace cert-manager --create-namespace --version v1.11.0 --set installCRDs=true
kubectl apply -f k8s/cluster-issuer.yaml
```



## Cleanup
To clean up AWS, simply run ```cd terraform & terraform destroy```
