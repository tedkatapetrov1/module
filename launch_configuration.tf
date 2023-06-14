# Create a Launch Configuration -----------------------------------------------
resource "aws_launch_template" "my_launch_template" {
  name_prefix            = "my-launch-template"
  image_id               = data.aws_ami.latest_amazon_linux.image_id
  instance_type          = "t2.micro"
  update_default_version = true
  iam_instance_profile {
    name = aws_iam_instance_profile.iam_instance_profile.name
  }
  tags = {
    Name = "my-launch-template"
  }

  vpc_security_group_ids = [aws_security_group.allow_sec1.id]

  user_data = base64encode(
    <<-EOF
    #!/bin/bash
    amazon-linux-extras install -y nginx1
    systemctl enable nginx --now
    EOF
  )
}

# Create a ASG ----------------------------------------------------------------
resource "aws_autoscaling_group" "my_autoscaling_group" {
  name = "my-exam-autoscaling-group"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = [aws_subnet.my_private_subnet_01.id, aws_subnet.my_private_subnet_02.id]
  target_group_arns   = [aws_lb_target_group.my_alb_target_group.arn]
  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"
  }
  tag {
    key = "Name"
    value = var.vpc_name
    propagate_at_launch = true
  }
}

# Create Auto Scale Policy ----------------------------------------------------

resource "aws_autoscaling_policy" "my_autoscaling_policy" {
  name                   = var.autoscalinggroup_name
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.my_autoscaling_group.name
}

# Cloudwatch config -----------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "my_cloudwatch_metric" {
  alarm_name          = var.cloudwatch_name
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.my_autoscaling_policy.arn]
}

# Attach Policy ---------------------------------------------------------------
resource "aws_autoscaling_attachment" "asg_attachment_lb" {
  autoscaling_group_name = aws_autoscaling_group.my_autoscaling_group.id
  lb_target_group_arn    = aws_lb_target_group.my_alb_target_group.arn
}
