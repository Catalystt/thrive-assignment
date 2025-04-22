terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


resource "aws_iam_role" "eks_cluster_role" {
  name               = "eksClusterRole"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Effect": "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


resource "aws_iam_role" "eks_worker_role" {
  name               = "eksWorkerNodeRole"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


resource "aws_iam_policy" "secretsstore_policy" {
  name        = "SecretsStorePolicyForCSI"
  description = "Policy allowing Secrets Store CSI Driver to retrieve secrets from AWS Secrets Manager"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "*"  // Optionally restrict to specific ARNs for enhanced security.
    }]
  })
}


resource "aws_iam_policy" "eks_logging_policy" {
  name        = "EKSLogging"
  description = "Policy allowing EKS Nodes to log to AWS CloudWatch"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:PutLogEvents",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogStreams",
                "logs:DescribeLogGroups",
                "logs:PutRetentionPolicy",
                "xray:PutTraceSegments",
                "xray:PutTelemetryRecords",
                "xray:GetSamplingRules",
                "xray:GetSamplingTargets",
                "xray:GetSamplingStatisticSummaries",
                "ssm:GetParameters"
            ],
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_eks_logging_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = aws_iam_policy.eks_logging_policy.arn
}

resource "aws_iam_role" "secrets_store_role" {
  name = "SecretsStoreRole"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::699475945643:oidc-provider/<OIDC_PROVIDER>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "<OIDC_PROVIDER>:sub": "system:serviceaccount:kube-system:secrets-store-csi-driver"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secretsstore_policy" {
  role       = aws_iam_role.secrets_store_role.name
  policy_arn = aws_iam_policy.secretsstore_policy.arn
}

module "vpc" {
  source              = "./modules/vpc"
  vpc_name            = "devops-vpc"
  cidr_block          = "10.0.0.0/16"
  public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
}


module "eks" {
  source                = "./modules/eks"
  cluster_name          = "devops-cluster"
  cluster_role_arn      = "arn:aws:iam::699475945643:role/eksClusterRole"
  subnet_ids            = module.vpc.public_subnet_ids
  endpoint_public_access  = true
  endpoint_private_access = false
}

module "eks_node_group" {
  source                = "./modules/autoscaling"
  cluster_name          = module.eks.cluster_id           # Output from your EKS module
  node_group_name       = "devops-node-group"
  node_role_arn         = "arn:aws:iam::699475945643:role/eksWorkerNodeRole"  # Your worker node IAM role ARN
  subnet_ids            = module.vpc.public_subnet_ids     # Using private subnets for workers
  desired_capacity      = 2
  min_size              = 1
  max_size              = 3
  instance_type         = "t3.micro"
  worker_ami_id         = "ami-0920121c85512b7db"           # Replace with your region's EKS-optimized AMI ID
}

resource "aws_sns_topic" "alert_topic" {
  name = "cloudwatch-alerts"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alert_topic.arn
  protocol  = "email"
  endpoint  = var.alert_email  # Set this value in your variables.tf or via Terraform CLI
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "HighCPUUsage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300                     # 5-minute period
  statistic           = "Average"
  threshold           = 70                      # Alert if CPU exceeds 70%
  alarm_description   = "Alarm when CPU utilization exceeds 70%"
  alarm_actions       = [aws_sns_topic.alert_topic.arn]
}
