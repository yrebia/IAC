project_id   = "team14-prd"
region       = "eu-west-2"
cluster_name = "tmgr-eks"

vpc_name       = "team14-prd-vpc"
cidr_block     = "10.1.0.0/16"
subnet_cidr    = "10.1.1.0/24"
subnet_az      = "eu-west-2b"
db_subnet_cidr = "10.1.2.0/24"
db_subnet_az   = "eu-west-2c"

# Database
db_engine            = "postgres"
db_engine_version    = "17.4"
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
db_name              = "appdbprod"
db_username          = "prod"
