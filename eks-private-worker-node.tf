# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/amazon-eks-nodegroup.yaml

#### User data for worker launch

locals {
  dev-node-private-userdata-v19 = <<USERDATA
#!/bin/bash -xe

sudo /etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.dev.endpoint}' --b64-cluster-ca '${aws_eks_cluster.dev.certificate_authority.0.data}' '${var.cluster-name}' \
--kubelet-extra-args "--kube-reserved cpu=2000m,memory=8Gi,ephemeral-storage=2Gi --system-reserved cpu=1000m,memory=1Gi,ephemeral-storage=2Gi \
--eviction-hard memory.available<1000Mi,nodefs.available<10%"
sudo yum -y install https://miq-public.s3.amazonaws.com/IT/SentinelAgent_linux_v21_5_3_2.rpm
sudo /opt/sentinelone/bin/sentinelctl management token set eyJ1cmwiOiAiaHR0cHM6Ly9hcG5lMS0xMTAxLW5mci5zZW50aW5lbG9uZS5uZXQiLCAic2l0ZV9rZXkiOiAiZTEzOGI3NDEwODFmNTU4ZCJ9
sudo /opt/sentinelone/bin/sentinelctl control start
sudo -u ec2-user bash -c 'aws s3 cp s3://miq-dev-devops/automate-job.sh /home/ec2-user/; chmod +x /home/ec2-user/automate-job.sh; /home/ec2-user/automate-job.sh'
USERDATA
}

resource "aws_launch_configuration" "dev-private-v19" {
  iam_instance_profile             = aws_iam_instance_profile.dev-node.name
  image_id                         = "ami-07c57f4106c84a3d0" # us-east-1 version 1.19
  instance_type                    = "m5.4xlarge"
  key_name                         = "rancher-dev"
  name_prefix                      = "dev-shared-eks-lc-v19"
  security_groups                  = [aws_security_group.dev-node.id]
  user_data_base64                 = base64encode(local.dev-node-private-userdata-v19)
  
  root_block_device {
    delete_on_termination = true
    encrypted             = false
    iops                  = 0
    volume_size = 100
    volume_type = "gp2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "dev-private-v19" {
  desired_capacity     = 9
  launch_configuration = aws_launch_configuration.dev-private-v19.id
  max_size             = 10
  min_size             = 9
  name                 = "dev-shared-eks-v19"
  vpc_zone_identifier  = aws_subnet.private-dev[*].id

  tag {
    key                 = "Name"
    value               = "dev-shared-eks-node-v19"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = ""
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster-name}"
    value               = ""
    propagate_at_launch = true
  }

  tag {
    key                 = "TEAM"
    value               = "DEVOPS"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "OWNER"
    value               = "SURESH"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "PRODUCT"
    value               = "EKS-DEV"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "ENVIRONMENT"
    value               = "DEVELOPMENT"
    propagate_at_launch = true
  }

}


# Adding EKS workers scaling policy for scale up/down 
# Creating Cloudwatch alarms for both scale up/down 

#resource "aws_autoscaling_policy" "eks-cpu-policy-private" {
#  name = "eks-cpu-policy-private"
#  autoscaling_group_name = "${aws_autoscaling_group.private-dev.name}"
#  adjustment_type = "ChangeInCapacity"
#  scaling_adjustment = "1"
#  cooldown = "300"
#  policy_type = "SimpleScaling"
#}

# scaling up cloudwatch metric
#resource "aws_cloudwatch_metric_alarm" "eks-cpu-alarm-private" {
#  alarm_name = "eks-cpu-alarm-private"
#  alarm_description = "eks-cpu-alarm-private"
#  comparison_operator = "GreaterThanOrEqualToThreshold"
#  evaluation_periods = "2"
#  metric_name = "CPUUtilization"
#  namespace = "AWS/EC2"
#  period = "120"
#  statistic = "Average"
#  threshold = "80"

#dimensions = {
#  "AutoScalingGroupName" = "${aws_autoscaling_group.private-dev.name}"
#}
#  actions_enabled = true
#  alarm_actions = ["${aws_autoscaling_policy.eks-cpu-policy-private.arn}"]
#}

# scale down policy
#resource "aws_autoscaling_policy" "eks-cpu-policy-scaledown-private" {
#  name = "eks-cpu-policy-scaledown-private"
#  autoscaling_group_name = "${aws_autoscaling_group.private-dev.name}"
#  adjustment_type = "ChangeInCapacity"
#  scaling_adjustment = "-1"
#  cooldown = "300"
#  policy_type = "SimpleScaling"
#}

# scale down cloudwatch metric
#resource "aws_cloudwatch_metric_alarm" "eks-cpu-alarm-scaledown-private" {
#  alarm_name = "eks-cpu-alarm-scaledown-private"
#  alarm_description = "eks-cpu-alarm-scaledown-private"
#  comparison_operator = "LessThanOrEqualToThreshold"
#  evaluation_periods = "2"
#  metric_name = "CPUUtilization"
#  namespace = "AWS/EC2"
#  period = "120"
#  statistic = "Average"
#  threshold = "5"

#dimensions = {
#  "AutoScalingGroupName" = "${aws_autoscaling_group.private-dev.name}"
#}
#  actions_enabled = true
#  alarm_actions = ["${aws_autoscaling_policy.eks-cpu-policy-scaledown-private.arn}"]
#}


####
#### Memory based scaling alarm and scaling policies
####

## scale up policy for eks node memory usage.

