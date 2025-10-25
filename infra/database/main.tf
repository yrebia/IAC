resource "aws_db_subnet_group" "main" {
  name       = "${var.project_id}-db-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "db" {
  name        = "${var.project_id}-db-sg"
  description = "Allow Postgres from EKS nodes"
  vpc_id      = var.vpc_id
}

# Autoriser Postgres (5432) depuis les CIDR applicatifs
resource "aws_vpc_security_group_ingress_rule" "db_postgres" {
  for_each          = toset(var.allowed_cidr_blocks)
  security_group_id = aws_security_group.db.id
  cidr_ipv4         = each.value
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  description       = "Allow Postgres from ${each.value}"
}

# Autoriser l'egress (par défaut aucun en provider >=5)
resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.db.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all egress"
}

resource "aws_db_instance" "main" {
  identifier                  = "${var.project_id}-database"
  engine                      = var.db_engine
  engine_version              = var.db_engine_version
  instance_class              = var.db_instance_class
  allocated_storage           = var.db_allocated_storage
  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true
  vpc_security_group_ids      = [aws_security_group.db.id]
  db_subnet_group_name        = aws_db_subnet_group.main.name
  publicly_accessible         = false
  skip_final_snapshot         = true
}