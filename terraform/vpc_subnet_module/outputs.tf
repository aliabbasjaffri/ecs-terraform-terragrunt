output "vpc_id" {
  value = module.vpc_subnet_module.vpc_id
}

output "vpc_arn" {
  value = module.vpc_subnet_module.vpc_arn
}

output "vpc_public_subnets_ids" {
  value = module.vpc_subnet_module.public_subnets
}

output "vpc_private_subnets_ids" {
  value = module.vpc_subnet_module.private_subnets
}
