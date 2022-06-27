variable "ecs_task" {
  type = object({
    family                   = string
    container_image_name     = string
    container_image          = string
    cpu                      = number
    memory                   = number
    requires_compatibilities = list(string)
    network_mode             = string
    container_image_port     = number
  })
}

variable "ecs_service" {
  type = object({
    name            = string
    cluster         = string
    launch_type     = string
    desired_count   = number
    egress_all_id   = string
    private_subnets = list(string)
  })
}

variable "vpc_id" {
  type = string
}

variable "alb_arn" {
  type = string
}