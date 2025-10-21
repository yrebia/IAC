resource "aws_db_subnet_group" "main" {
  name       = "${var.project_id}-db-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "db" {
  name        = "${var.project_id}-db-sg"
  description = "Allow Postgres from EKS nodes"
  vpc_id      = var.vpc_id
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