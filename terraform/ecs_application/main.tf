data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution_role" {
  name               = "task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

data "aws_iam_policy" "ecs_task_execution_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = data.aws_iam_policy.ecs_task_execution_role.arn
}

## --------------------------------------------------------------------------- ##

resource "aws_ecs_task_definition" "ecs_task" {
  family                = var.ecs_task.family
  container_definitions = <<EOF
  [
    {
    "name": "${var.ecs_task.container_image_name}",
    "image": "${var.ecs_task.container_image}",
    "portMappings": [
        {
          "containerPort": 2368
        }
    ]}
  ]
  EOF

  cpu                      = var.ecs_task.cpu
  memory                   = var.ecs_task.memory
  requires_compatibilities = var.ecs_task.requires_compatibilities
  network_mode             = var.ecs_task.network_mode
  execution_role_arn       = aws_iam_role.task_execution_role.arn
}

resource "aws_ecs_service" "ecs_service" {
  name            = var.ecs_service.name
  cluster         = var.ecs_service.cluster
  task_definition = aws_ecs_task_definition.ecs_task.arn
  launch_type     = var.ecs_service.launch_type
  desired_count   = var.ecs_service.desired_count

  load_balancer {
    target_group_arn = aws_lb_target_group.ghost_api.arn
    container_name   = var.ecs_task.container_image_name
    container_port   = var.ecs_task.container_image_port
  }

  network_configuration {
    assign_public_ip = false

    security_groups = [
      var.ecs_service.egress_all_id,
      aws_security_group.ingress_api.id,
    ]

    subnets = var.ecs_service.private_subnets
  }
}

resource "aws_lb_target_group" "ghost_api" {
  name        = "ghost-api"
  port        = var.ecs_task.container_image_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled = true
    path    = "/"
  }
}

resource "aws_alb_listener" "http_listener" {
  load_balancer_arn = var.alb_arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ghost_api.arn
  }
}

resource "aws_security_group" "ingress_api" {
  name        = "ingress-api"
  description = "Allow ingress to API"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.ecs_task.container_image_port
    to_port     = var.ecs_task.container_image_port
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}