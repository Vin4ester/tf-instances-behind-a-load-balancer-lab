data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_launch_template" "main" {
  name          = var.aws_launch_template_name
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  key_name      = var.key_name

  network_interfaces {
    security_groups       = [var.ssh_inbound_id, var.http_inbound_id]
    delete_on_termination = true
  }

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd jq
    systemctl enable httpd
    systemctl start httpd

    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/instance-id)
    PRIVATE_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/local-ipv4)

    echo "This message was generated on instance $INSTANCE_ID with the following IP: $PRIVATE_IP" \
      > /var/www/html/index.html
  EOF
  )

  tags = {
    Terraform = "true"
    Project   = var.project_id
  }
}

resource "aws_lb_target_group" "main" {
  name     = "${var.project_id}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Terraform = "true"
    Project   = var.project_id
  }
}

resource "aws_lb" "main" {
  name               = var.load_balancer
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.lb_http_inbound_id]
  subnets            = [var.public_subnet_a_id, var.public_subnet_b_id]

  tags = {
    Terraform = "true"
    Project   = var.project_id
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  tags = {
    Terraform = "true"
    Project   = var.project_id
  }
}

resource "aws_autoscaling_group" "main" {
  name                = var.aws_asg_name
  desired_capacity    = 2
  min_size            = 1
  max_size            = 2
  vpc_zone_identifier = [var.public_subnet_a_id, var.public_subnet_b_id]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [load_balancers, target_group_arns]
  }

  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_id
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "main" {
  autoscaling_group_name = aws_autoscaling_group.main.name
  lb_target_group_arn    = aws_lb_target_group.main.arn
}
