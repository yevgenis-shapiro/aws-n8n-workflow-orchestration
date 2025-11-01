resource "aws_db_instance" "database" {
  depends_on          = [aws_iam_role.iam-role-RDS]
  db_name             = var.database-name
  identifier          = "${var.environment-prefix}-${var.db-engine}-${var.database-name}"
  instance_class      = var.db-instance-type
  engine              = var.db-engine
  engine_version      = var.db-engine-version
  skip_final_snapshot = true
  allocated_storage   = var.db-volume-size
  storage_encrypted   = true

  username = var.db-admin-username
  password = var.db-admin-password

  db_subnet_group_name   = var.db-subnet-group
  parameter_group_name   = var.db-pg-parameter-group
  vpc_security_group_ids = [aws_security_group.database-security-group.id]

  enabled_cloudwatch_logs_exports = var.db-engine == "postgres" ? ["postgresql", "upgrade"] : ["alert", "audit", "listener", "trace"]
  monitoring_interval             = 5
  monitoring_role_arn = aws_iam_role.iam-role-RDS.arn

  multi_az = true
  
  ca_cert_identifier = var.ca_cert_identifier

  tags = var.tags
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "iam-role-RDS" {

  name = "${var.environment-prefix}-rds-role"
  assume_role_policy = jsonencode({
         Version = "2012-10-17"
          Statement = [
            {
              Action = "sts:AssumeRole"
              Effect = "Allow"
              Principal = {
                Service = "monitoring.rds.amazonaws.com"
             }
            },
          ]
        })

  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"]

  tags = var.tags
}

resource "aws_security_group" "database-security-group" {
  name   = "${var.environment-prefix}-${var.database-name}-security-group"
  vpc_id = var.vpc-id

  ingress {
    from_port       = var.db-engine == "postgres" ? 5432 : 1521
    protocol        = "TCP"
    to_port         = var.db-engine == "postgres" ? 5432 : 1521
    security_groups = var.client-security-group-ids
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment-prefix}-${var.db-engine}"
  })
}
