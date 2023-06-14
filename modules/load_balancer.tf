# Create a Load Balancer ------------------------------------------------------
resource "aws_lb" "my_load_balancer" {
  name               = var.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http.id]
  subnets            = [aws_subnet.my_public_subnet_01.id, aws_subnet.my_public_subnet_02.id]

  enable_deletion_protection = false
  tags = {
    Name = "load-balancer"
  }
}

# Create a Load Balancer Target Group -----------------------------------------

resource "aws_lb_target_group" "my_alb_target_group" {
  name     = var.lbtargetgroup_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc_01.id
}

# Create a Load Balancer Listener ---------------------------------------------
resource "aws_lb_listener" "my_alb_listener" {
  load_balancer_arn = aws_lb.my_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  tags = {
    Name = "listener"
  }
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_alb_target_group.arn
  }
}