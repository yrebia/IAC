project_id   = "team1-dev"
region       = "eu-west-3"
cluster_name = "tmgr-eks3"

vpc_name       = "team1-dev-vpc"
cidr_block     = "10.0.0.0/16"
subnet_cidr    = "10.0.1.0/24"
subnet_az      = "eu-west-3b"
db_subnet_cidr = "10.0.2.0/24"
db_subnet_az   = "eu-west-3c"

# Database
db_engine            = "postgres"
db_engine_version    = "17.4"
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
db_name              = "appdbdev"
db_username          = "dev"
vpc_id               = "vpc-021490dfd686bd62e"
