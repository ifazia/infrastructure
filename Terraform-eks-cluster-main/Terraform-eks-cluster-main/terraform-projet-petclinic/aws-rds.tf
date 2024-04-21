resource "aws_db_subnet_group" "petclinic_db_subnet" {
 name    = "petclinic_db_subnet"
 subnet_ids = [aws_subnet.public_subnet_a.id,aws_subnet.public_subnet_b.id] # Spécifiez les sous-réseaux souhaités
}

#Security group pour mysql
resource "aws_security_group" "petclinic_sg_mysql" {
 name  = "petclinic_sg_mysql"
 vpc_id = "${aws_vpc.petclinic_vpc.id}"
 ingress {
   from_port  = 3306
   to_port   = 3306
   protocol = "tcp"
   cidr_blocks = [var.cidr_public_subnet_a,var.cidr_public_subnet_b]
 }
 tags = {
  Name = "petclinic-sg-mysql"
 }
}

resource "aws_db_instance" "vet-db" {
 allocated_storage  = 10
 storage_type     = "gp2"
 engine        = "mysql"
 engine_version    = "5.7"
 instance_class    = "db.t3.micro"
 identifier      = "vet-db"
 username       = var.petclinic_user
 password       = var.petclinic_mysql_pwd
 parameter_group_name = "default.mysql5.7"
 skip_final_snapshot = true
 availability_zone = var.az_a
 vpc_security_group_ids = [aws_security_group.petclinic_sg_mysql.id]
 db_subnet_group_name = aws_db_subnet_group.petclinic_db_subnet.name
 backup_retention_period = 1
}

resource "aws_db_instance" "customer-db" {
 allocated_storage  = 10
 storage_type     = "gp2"
 engine        = "mysql"
 engine_version    = "5.7"
 instance_class    = "db.t3.micro"
 identifier      = "customer-db"
 username       = var.petclinic_user
 password       = var.petclinic_mysql_pwd
 parameter_group_name = "default.mysql5.7"
 skip_final_snapshot = true
 availability_zone = var.az_a
 vpc_security_group_ids = [aws_security_group.petclinic_sg_mysql.id]
 db_subnet_group_name = aws_db_subnet_group.petclinic_db_subnet.name
 backup_retention_period = 1
}

resource "aws_db_instance" "visit-db" {
 allocated_storage  = 10
 storage_type     = "gp2"
 engine        = "mysql"
 engine_version    = "5.7"
 instance_class    = "db.t3.micro"
 identifier      = "visit-db"
 username       = var.petclinic_user
 password       = var.petclinic_mysql_pwd
 parameter_group_name = "default.mysql5.7"
 skip_final_snapshot = true
 availability_zone = var.az_a
 vpc_security_group_ids = [aws_security_group.petclinic_sg_mysql.id]
 db_subnet_group_name = aws_db_subnet_group.petclinic_db_subnet.name
 backup_retention_period = 1
}

#














