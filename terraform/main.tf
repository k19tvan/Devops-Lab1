module "network" {
  source = "./modules/network"

  project_name        = "nt548-lab01"
  vpc_cidr            = "10.0.0.0/16"
  availability_zone   = "us-east-1a"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
}

module "routing" {
  source = "./modules/routing"

  project_name        = "nt548-lab01"
  vpc_id              = module.network.vpc_id
  public_subnet_id    = module.network.public_subnet_id
  internet_gateway_id = module.network.internet_gateway_id

  private_subnet_id = module.network.private_subnet_id
  nat_gateway_id    = module.nat.nat_gateway_id
}

module "nat" {
  source = "./modules/nat"

  project_name     = "nt548-lab01"
  public_subnet_id = module.network.public_subnet_id

  depends_on = [module.network]
}

module "security" {
  source = "./modules/security"

  project_name     = "nt548-lab01"
  vpc_id           = module.network.vpc_id
  allowed_ssh_cidr = "125.235.233.10/32"
}

module "compute" {
  source = "./modules/compute"

  project_name  = "nt548-lab01"
  instance_type = "t3.micro"
  key_name      = "nt548-lab01-key"

  public_subnet_id  = module.network.public_subnet_id
  private_subnet_id = module.network.private_subnet_id

  public_security_group_id  = module.security.public_security_group_id
  private_security_group_id = module.security.private_security_group_id

  depends_on = [
    module.routing,
    module.security
  ]
}