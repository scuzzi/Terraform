
output "address" {
    value = aws_db_instance.example.address
    description = "Connect to the database at the endpoint"
}

output "port" {
value = aws_db_instance.example.port
description = "The port the database is listening on"

}